import random
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Sequence

import polars as pl
from faker import Faker
from sqlalchemy import select, literal, ColumnElement
from sqlalchemy.orm import Session, contains_eager, joinedload
from sqlalchemy.sql import expression, func, or_, and_
from tqdm import tqdm

from online_food_ordering_system_seeder import models


def if_then(p, *q) -> ColumnElement[bool]:
    return or_(~p, and_(*q))


class Seeder:
    def __init__[T](self, session: Session):
        self.session = session
        self.faker = Faker()

        self.now = datetime.now()
        self.tables: dict[type[T], Sequence[T]] = {}

    def refresh_cache(self) -> None:
        self.tables = {
            models.Member: self.session.scalars(select(models.Member)
                                                .options(joinedload(models.Member.addresses),
                                                         joinedload(models.Member.subscriptions),
                                                         joinedload(models.Member.orders),
                                                         joinedload(models.Member.vouchers))).unique().all(),
            models.PaymentMethod: self.session.scalars(select(models.PaymentMethod)).all(),
            models.Membership: self.session.scalars(select(models.Membership)).all(),
            models.Restaurant: self.session.scalars(select(models.Restaurant)).all(),
            models.DeliveryVendor: self.session.scalars(select(models.DeliveryVendor)).all(),
            models.Voucher: self.session.scalars(select(models.Voucher)
                                                 .options(joinedload(models.Voucher.distributed_to))).unique().all()
        }

    def __enter__(self):
        self.session.__enter__()
        self.refresh_cache()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.session.commit()
        self.session.__exit__(exc_type, exc_val, exc_tb)

    @staticmethod
    def _score(columns: list):
        expr = columns[0].is_not(expression.Null())
        for e in columns[1:]:
            expr += e.is_not(expression.Null())
        return expr

    def _get_product_price(self, product: models.Product) -> Decimal:
        stmt = select(models.PriceComponent) \
            .where(models.PriceComponent.product_id == product.id) \
            .where(models.PriceComponent.price_type == models.PriceComponent.PriceType.BASE) \
            .where(models.PriceComponent.product_feature_id.is_(expression.Null())) \
            .where(models.PriceComponent.product_category_id.is_(expression.Null())) \
            .where(models.PriceComponent.quantity_break_id.is_(expression.Null())) \
            .where(models.PriceComponent.order_value_id.is_(expression.Null())) \
            .where(models.PriceComponent.restaurant_id.is_(expression.Null())) \
            .where(models.PriceComponent.membership_id.is_(expression.Null())) \
            .where(models.PriceComponent.voucher_id.is_(expression.Null())) \
            .where(models.PriceComponent.vendor_id.is_(expression.Null())) \
            .where(models.PriceComponent.from_date < self.now) \
            .where(func.coalesce(models.PriceComponent.thru_date, func.now()) > self.now) \
            .order_by(models.PriceComponent.from_date)
        price: models.PriceComponent = self.session.scalars(stmt).first()
        assert price.amount is not None
        return price.amount

    def _get_product_feature_price(self, product_feature: models.ProductFeature) -> Decimal:
        stmt = select(models.PriceComponent) \
            .where(models.PriceComponent.product_feature_id == product_feature.id) \
            .where(models.PriceComponent.price_type == models.PriceComponent.PriceType.BASE) \
            .where(models.PriceComponent.product_id.is_(expression.Null())) \
            .where(models.PriceComponent.product_category_id.is_(expression.Null())) \
            .where(models.PriceComponent.quantity_break_id.is_(expression.Null())) \
            .where(models.PriceComponent.order_value_id.is_(expression.Null())) \
            .where(models.PriceComponent.restaurant_id.is_(expression.Null())) \
            .where(models.PriceComponent.membership_id.is_(expression.Null())) \
            .where(models.PriceComponent.voucher_id.is_(expression.Null())) \
            .where(models.PriceComponent.vendor_id.is_(expression.Null())) \
            .where(models.PriceComponent.from_date < self.now) \
            .where(func.coalesce(models.PriceComponent.thru_date, func.now()) > self.now) \
            .order_by(models.PriceComponent.from_date)
        price: models.PriceComponent = self.session.scalars(stmt).first()
        assert price.amount is not None
        return price.amount

    def _add_order_item_surcharges(self, order_item: models.OrderItem) -> None:
        order = order_item.order
        subscription = order.member.get_current_subscription(self.now)

        prices: Sequence[models.PriceComponent] = self.session.scalars(
            select(models.PriceComponent)
            .where(if_then(models.PriceComponent.product_id.is_not(expression.Null()),
                           models.PriceComponent.product_id == order_item.product.id))
            .where(models.PriceComponent.product_feature_id.is_(expression.Null()))
            .where(models.PriceComponent.product_category_id.is_(expression.Null()))
            .where(if_then(models.PriceComponent.quantity_break_id.is_not(expression.Null()),
                           literal(order_item.quantity).between(
                               models.QuantityBreak.from_quantity,
                               func.coalesce(models.QuantityBreak.thru_quantity))))
            .where(if_then(models.PriceComponent.restaurant_id.is_not(expression.Null()),
                           and_(models.PriceComponent.product_id.is_not(expression.Null()),
                                models.PriceComponent.restaurant_id == order.restaurant_id)))
            .where(if_then(models.PriceComponent.membership_id.is_not(expression.Null()),
                           and_(models.PriceComponent.product_id.is_not(expression.Null()),
                                (models.PriceComponent.membership_id == subscription.membership_id)
                                if subscription is not None else literal(False))))
            .where(models.PriceComponent.order_value_id.is_(expression.Null()))  # for order only
            .where(models.PriceComponent.vendor_id.is_(expression.Null()))  # for order only
            .where(models.PriceComponent.voucher_id.is_(expression.Null()))  # not handled here
            .where(literal(self.now).between(
                models.PriceComponent.from_date,
                func.coalesce(models.PriceComponent.thru_date, func.now())))
            .join(models.PriceComponent.quantity_break, is_outer=True)
        ).all()
        for price in prices:
            adjustment_type = models.OrderItemAdjustment.AdjustmentType.SURCHARGE
            if price.price_type == models.PriceComponent.PriceType.DISCOUNT:
                adjustment_type = models.OrderItemAdjustment.AdjustmentType.DISCOUNT

            order_item.adjustments.add(models.OrderItemAdjustment(
                order=order_item.order,
                order_item=order_item,
                adjustment_type=adjustment_type,
                amount=price.amount,
                percentage=price.percentage
            ))

    def _add_order_item_feature_surcharge(self, order_item_feature: models.OrderItemFeature) -> None:
        order = order_item_feature.order_item.order
        subscription = order.member.get_current_subscription(self.now)

        prices: Sequence[models.PriceComponent] = self.session.scalars(
            select(models.PriceComponent)
            .where(if_then(models.PriceComponent.product_id.is_not(expression.Null()),
                           models.PriceComponent.product_id == order_item_feature.order_item.product.id))
            .where(if_then(models.PriceComponent.product_feature_id.is_not(expression.Null()),
                           models.PriceComponent.product_feature_id == order_item_feature.product_feature_id))
            .where(models.PriceComponent.product_category_id.is_(expression.Null()))
            .where(if_then(models.PriceComponent.quantity_break_id.is_not(expression.Null()),
                           literal(order_item_feature.quantity).between(
                               models.QuantityBreak.from_quantity,
                               func.coalesce(models.QuantityBreak.thru_quantity))))
            .where(if_then(models.PriceComponent.restaurant_id.is_not(expression.Null()),
                           and_(models.PriceComponent.product_id.is_not(expression.Null()),
                                models.PriceComponent.restaurant_id == order.restaurant_id)))
            .where(if_then(models.PriceComponent.membership_id.is_not(expression.Null()),
                           and_(models.PriceComponent.product_id.is_not(expression.Null()),
                                (models.PriceComponent.membership_id == subscription.membership_id)
                                if subscription is not None else literal(False))))
            .where(models.PriceComponent.order_value_id.is_(expression.Null()))  # for order only
            .where(models.PriceComponent.vendor_id.is_(expression.Null()))  # for order only
            .where(models.PriceComponent.voucher_id.is_(expression.Null()))  # not handled here
            .where(literal(self.now).between(
                models.PriceComponent.from_date,
                func.coalesce(models.PriceComponent.thru_date, func.now())))
            .join(models.PriceComponent.quantity_break, is_outer=True)
        ).all()
        for price in prices:
            adjustment_type = models.OrderItemAdjustment.AdjustmentType.SURCHARGE
            if price.price_type == models.PriceComponent.PriceType.DISCOUNT:
                adjustment_type = models.OrderItemAdjustment.AdjustmentType.DISCOUNT

            order_item_feature.order_item.adjustments.add(models.OrderItemAdjustment(
                order=order_item_feature.order_item.order,
                order_item=order_item_feature.order_item,
                adjustment_type=adjustment_type,
                amount=price.amount,
                percentage=price.percentage
            ))

    def _add_order_surcharges(self, order: models.Orders) -> None:
        subscription = order.member.get_current_subscription(self.now)

        prices: Sequence[models.PriceComponent] = self.session.scalars(
            select(models.PriceComponent)
            .where(models.PriceComponent.product_id.is_(expression.Null()))  # for products
            .where(models.PriceComponent.product_feature_id.is_(expression.Null()))  # for products
            .where(models.PriceComponent.product_category_id.is_(expression.Null()))  # for products
            .where(models.PriceComponent.quantity_break_id.is_(expression.Null()))  # for products
            .where(if_then(models.PriceComponent.order_value_id.is_not(expression.Null()),
                           literal(order.subtotal).between(
                               models.OrderValue.from_amount,
                               models.OrderValue.thru_amount)))
            .where(if_then(models.PriceComponent.restaurant_id.is_not(expression.Null()),
                           and_(models.PriceComponent.product_id.is_(expression.Null()),
                                models.PriceComponent.restaurant_id == order.restaurant_id)))
            .where(if_then(models.PriceComponent.membership_id.is_not(expression.Null()),
                           and_(models.PriceComponent.product_id.is_(expression.Null()),
                                (models.PriceComponent.membership_id == subscription.membership_id)
                                if subscription is not None else literal(False))))
            .where(if_then(models.PriceComponent.vendor_id.is_not(expression.Null()),
                           (models.PriceComponent.vendor_id == order.delivery.vendor_id)
                           if order.delivery is not None else literal(False)))
            .where(models.PriceComponent.voucher_id.is_(expression.Null()))  # not handled here
            .where(literal(self.now).between(
                models.PriceComponent.from_date,
                func.coalesce(models.PriceComponent.thru_date, func.now())))
            .join(models.PriceComponent.order_value, is_outer=True)
        ).all()
        for price in prices:
            adjustment_type = models.OrderItemAdjustment.AdjustmentType.SURCHARGE
            if price.vendor_id:
                adjustment_type = models.OrderItemAdjustment.AdjustmentType.SHIPPING

            if price.price_type == models.PriceComponent.PriceType.DISCOUNT:
                adjustment_type = models.OrderItemAdjustment.AdjustmentType.DISCOUNT

            order.adjustments.add(models.OrderItemAdjustment(
                order=order,
                adjustment_type=adjustment_type,
                amount=price.amount,
                percentage=price.percentage
            ))

    def _apply_first_order_item_voucher(self, order_item: models.OrderItem,
                                        member: models.Member) -> models.VoucherDistribution | None:
        order = order_item.order
        subscription = order.member.get_current_subscription(self.now)

        price: models.PriceComponent | None = self.session.scalars(
            select(models.PriceComponent)
            .where(models.PriceComponent.voucher_id.in_(
                (voucher.voucher_id for voucher in filter(lambda d: d.redemption is None, member.vouchers))))
            .where(models.PriceComponent.product_id == order_item.product.id)
            .where(models.PriceComponent.product_feature_id.is_(expression.Null()))
            .where(models.PriceComponent.product_category_id.is_(expression.Null()))
            .where(if_then(models.PriceComponent.quantity_break_id.is_not(expression.Null()),
                           literal(order_item.quantity).between(
                               models.QuantityBreak.from_quantity,
                               func.coalesce(models.QuantityBreak.thru_quantity))))
            .where(if_then(models.PriceComponent.restaurant_id.is_not(expression.Null()),
                           and_(models.PriceComponent.product_id.is_not(expression.Null()),
                                models.PriceComponent.restaurant_id == order.restaurant_id)))
            .where(if_then(models.PriceComponent.membership_id.is_not(expression.Null()),
                           and_(models.PriceComponent.product_id.is_not(expression.Null()),
                                (models.PriceComponent.membership_id == subscription.membership_id)
                                if subscription is not None else literal(False))))
            .where(models.PriceComponent.order_value_id.is_(expression.Null()))  # for order only
            .where(models.PriceComponent.vendor_id.is_(expression.Null()))  # for order only
            .where(models.PriceComponent.voucher_id.is_(expression.Null()))  # not handled here
            .where(literal(self.now).between(
                models.PriceComponent.from_date,
                func.coalesce(models.PriceComponent.thru_date, func.now())))
            .join(models.PriceComponent.quantity_break, is_outer=True)
        ).one_or_none()

        if price is None:
            return None

        order_item.adjustments.add(models.OrderItemAdjustment(
            order=order,
            adjustment_type=models.OrderItemAdjustment.AdjustmentType.DISCOUNT,
            amount=price.amount,
            percentage=price.percentage
        ))
        for voucher in member.vouchers:
            if voucher.redemption is not None:
                continue

            if voucher.voucher_id == price.voucher_id:
                voucher.redemption = models.VoucherRedemption(
                    voucher_distribution=voucher
                )
                return voucher
        return None

    def _apply_first_order_item_feature_voucher(self, order_item_feature: models.OrderItemFeature,
                                                member: models.Member) -> models.VoucherDistribution | None:
        order = order_item_feature.order_item.order
        subscription = order.member.get_current_subscription(self.now)

        price: models.PriceComponent | None = self.session.scalars(
            select(models.PriceComponent)
            .where(models.PriceComponent.voucher_id.in_(
                (voucher.voucher_id for voucher in filter(lambda d: d.redemption is None, member.vouchers))))
            .where(models.PriceComponent.product_id.is_(expression.Null()))
            .where(models.PriceComponent.product_feature_id == order_item_feature.product_feature.id)
            .where(models.PriceComponent.product_category_id.is_(expression.Null()))
            .where(if_then(models.PriceComponent.quantity_break_id.is_not(expression.Null()),
                           literal(order_item_feature.quantity).between(
                               models.QuantityBreak.from_quantity,
                               func.coalesce(models.QuantityBreak.thru_quantity))))
            .where(if_then(models.PriceComponent.restaurant_id.is_not(expression.Null()),
                           and_(models.PriceComponent.product_id.is_not(expression.Null()),
                                models.PriceComponent.restaurant_id == order.restaurant_id)))
            .where(if_then(models.PriceComponent.membership_id.is_not(expression.Null()),
                           and_(models.PriceComponent.product_id.is_not(expression.Null()),
                                (models.PriceComponent.membership_id == subscription.membership_id)
                                if subscription is not None else literal(False))))
            .where(models.PriceComponent.order_value_id.is_(expression.Null()))  # for order only
            .where(models.PriceComponent.vendor_id.is_(expression.Null()))  # for order only
            .where(models.PriceComponent.voucher_id.is_(expression.Null()))  # not handled here
            .where(literal(self.now).between(
                models.PriceComponent.from_date,
                func.coalesce(models.PriceComponent.thru_date, func.now())))
            .join(models.PriceComponent.quantity_break, is_outer=True)
        ).one_or_none()

        if price is None:
            return None

        order_item_feature.order_item.adjustments.add(models.OrderItemAdjustment(
            order=order,
            adjustment_type=models.OrderItemAdjustment.AdjustmentType.DISCOUNT,
            amount=price.amount,
            percentage=price.percentage
        ))
        for voucher in member.vouchers:
            if voucher.redemption is not None:
                continue

            if voucher.voucher_id == price.voucher_id:
                voucher.redemption = models.VoucherRedemption(
                    voucher_distribution=voucher
                )
                return voucher
        return None

    def _apply_first_order_voucher(self, order: models.Orders,
                                   member: models.Member) -> models.VoucherDistribution | None:
        subscription = order.member.get_current_subscription(self.now)

        price: models.PriceComponent | None = self.session.scalars(
            select(models.PriceComponent)
            .where(models.PriceComponent.voucher_id.in_(
                (voucher.voucher_id for voucher in filter(lambda d: d.redemption is None, member.vouchers))))
            .where(models.PriceComponent.product_id.is_(expression.Null()))  # for products
            .where(models.PriceComponent.product_feature_id.is_(expression.Null()))  # for products
            .where(models.PriceComponent.product_category_id.is_(expression.Null()))  # for products
            .where(models.PriceComponent.quantity_break_id.is_(expression.Null()))  # for products
            .where(if_then(models.PriceComponent.order_value_id.is_not(expression.Null()),
                           literal(order.subtotal).between(
                               models.OrderValue.from_amount,
                               models.OrderValue.thru_amount)))
            .where(if_then(models.PriceComponent.restaurant_id.is_not(expression.Null()),
                           and_(models.PriceComponent.product_id.is_(expression.Null()),
                                models.PriceComponent.restaurant_id == order.restaurant_id)))
            .where(if_then(models.PriceComponent.membership_id.is_not(expression.Null()),
                           and_(models.PriceComponent.product_id.is_(expression.Null()),
                                (models.PriceComponent.membership_id == subscription.membership_id)
                                if subscription is not None else literal(False))))
            .where(if_then(models.PriceComponent.vendor_id.is_not(expression.Null()),
                           (models.PriceComponent.vendor_id == order.delivery.vendor_id)
                           if order.delivery is not None else literal(False)))
            .where(models.PriceComponent.voucher_id.is_(expression.Null()))  # not handled here
            .where(literal(self.now).between(
                models.PriceComponent.from_date,
                func.coalesce(models.PriceComponent.thru_date, func.now())))
            .join(models.PriceComponent.order_value, is_outer=True)
        ).one_or_none()

        if price is None:
            return None

        order.adjustments.add(models.OrderItemAdjustment(
            order=order,
            adjustment_type=models.OrderItemAdjustment.AdjustmentType.DISCOUNT,
            amount=price.amount,
            percentage=price.percentage
        ))
        for voucher in member.vouchers:
            if voucher.redemption is not None:
                continue

            if voucher.voucher_id == price.voucher_id:
                voucher.redemption = models.VoucherRedemption(
                    voucher_distribution=voucher
                )
                return voucher
        return None

    def _create_order(self, member: models.Member, restaurant: models.Restaurant,
                      order_time: datetime) -> models.Orders:
        order = models.Orders(
            member_id=member.id,
            ordered_at=order_time,
            order_type=random.choice((models.Orders.OrderType.DELIVERY, models.Orders.OrderType.PICKUP))
        )
        if order.order_type == models.Orders.OrderType.DELIVERY:
            delivery = models.Delivery(
                order=order,
                address_id=random.choice(tuple(member.addresses)).address_id,
                vendor_id=random.choice(self.tables[models.DeliveryVendor]).id,
                ordered_at=order_time,
                estimated_arrive_at=self.faker.date_time_between(
                    start_date=order_time + timedelta(minutes=5),
                    end_date=order_time + timedelta(hours=1)
                )
            )
            order.delivery = delivery

        vouchers: list[models.VoucherDistribution] = []

        stmt = select(models.MenuItem) \
            .options(contains_eager(models.MenuItem.product),
                     contains_eager(models.MenuItem.product)
                     .contains_eager(models.Product.attributes)
                     .contains_eager(models.ProductAttribute.product_feature_group)
                     .contains_eager(models.ProductFeatureGroup.fields)
                     .contains_eager(models.ProductFeatureGroupField.product_feature)) \
            .where(models.MenuItem.restaurant_id == restaurant.id) \
            .join(models.MenuItem.product) \
            .where(order_time > models.Product.introduction_date) \
            .join(models.Product.attributes) \
            .join(models.ProductAttribute.product_feature_group) \
            .join(models.ProductFeatureGroup.fields) \
            .join(models.ProductFeatureGroupField.product_feature)
        menu_items = self.session.scalars(stmt).all()
        for menu_item in random.choices(menu_items, k=random.randint(1, len(menu_items) // 3)):
            product = menu_item.product
            quantity = random.randint(1, 3)

            order_item = models.OrderItem(
                order=order,
                product=product,
                quantity=quantity,
                unit_price=self._get_product_price(product)
            )
            order.items.add(order_item)
            self._add_order_item_surcharges(order_item)
            if random.randint(1, 2) == 1:
                voucher = self._apply_first_order_item_voucher(order_item, member)
                if voucher:
                    vouchers.append(voucher)

            for attribute in product.attributes:
                attribute: models.ProductAttribute
                group = attribute.product_feature_group

                if random.randint(0, 1) == 0:
                    k = random.randint(group.min, (group.max or len(group.fields)))
                else:
                    k = group.min

                for field in random.choices(tuple(group.fields), k=k):
                    field: models.ProductFeatureGroupField
                    product_feature = field.product_feature

                    order_item_feature = models.OrderItemFeature(
                        product_feature=product_feature,
                        order_item=order_item,
                        quantity=quantity,
                        unit_price=self._get_product_feature_price(product_feature)
                    )
                    order_item.features.add(order_item_feature)
                    self._add_order_item_feature_surcharge(order_item_feature)
                    if random.randint(1, 2) == 1:
                        voucher = self._apply_first_order_item_feature_voucher(order_item_feature, member)
                        if voucher:
                            vouchers.append(voucher)

        self._add_order_surcharges(order)
        if random.randint(1, 2) == 1:
            voucher = self._apply_first_order_voucher(order, member)
            if voucher:
                vouchers.append(voucher)
        total = order.subtotal

        payment = models.Payment(
            payment_method_id=random.choice(self.tables[models.PaymentMethod]).id,
            paid_at=order_time,
            ref_no=self.faker.pystr(min_chars=16, max_chars=16),
            amount=total,
            payment_method_data="{}"
        )
        invoice = models.Invoice(
            order=order,
            payment=payment,
            invoiced_at=order_time,
            amount=total
        )
        for voucher in vouchers:
            assert voucher.redemption is not None
            voucher.redemption.invoice = invoice
            invoice.vouchers.add(voucher.redemption)
        order.invoice = invoice

        return order

    def seed_memberships(self) -> None:
        members = self.tables[models.Member]
        for member in random.choices(members, k=len(members) // 8):
            membership = random.choice(self.tables[models.Membership])
            payment_method = random.choice(self.tables[models.PaymentMethod])

            if random.randint(1, 3) == 1:
                current_dt = member.created_at
                end_dt = self.now
            else:
                current_dt = self.faker.date_time_between(member.created_at, self.now)
                end_dt = current_dt + timedelta(days=1)

            while current_dt < end_dt:
                payment = models.Payment(
                    payment_method_id=payment_method.id,
                    paid_at=current_dt,
                    ref_no=self.faker.pystr(min_chars=16, max_chars=16),
                    amount=membership.price,
                    payment_method_data="{}"
                )
                subscription = models.MonthlySubscription(
                    membership_id=membership.id,
                    member_id=member.id,
                    from_date=current_dt,
                    thru_date=current_dt + timedelta(days=30)
                )
                subscription.payments.add(models.SubscriptionPayment(
                    payment=payment,
                    monthly_subscription=subscription
                ))
                member.subscriptions.add(subscription)
                current_dt += timedelta(days=30)

        self.session.commit()

    def seed_vouchers(self) -> None:
        def distribute_randomly(voucher: models.Voucher) -> None:
            for member in random.choices(self.tables[models.Member], k=voucher.usage_limit + random.randint(-100, 100)):
                voucher.distributed_to.add(models.VoucherDistribution(
                    member=member,
                    voucher=voucher
                ))

        def make_generic_voucher(name, description, created_by_id) -> models.Voucher:
            return models.Voucher(
                name=name,
                description=description,
                usage_limit=random.randint(100, 500),
                from_date=day,
                thru_date=day + timedelta(days=random.randint(10, 31)),
                created_by_id=created_by_id
            )

        def make_generic_price(voucher: models.Voucher, value: Decimal) -> models.PriceComponent:
            return models.PriceComponent(
                price_type=models.PriceComponent.PriceType.DISCOUNT,
                voucher=voucher,
                description=voucher.description,
                from_date=voucher.from_date,
                thru_date=voucher.thru_date,
                amount=value if value >= 1 else None,
                percentage=value if value < 1 else None,
                created_by_id=voucher.created_by_id
            )

        for restaurant in tqdm(self.tables[models.Restaurant], desc="Picking restaurants"):

            days = pl.date_range(start=restaurant.introduction_date, end=self.now, interval="1d", eager=True)
            for i, day in enumerate(tqdm(days.sample(fraction=1 / 6).sort(), desc="Seeding vouchers"), start=1):
                if random.randint(1, 2) == 1:
                    value = Decimal(f"0.{random.randint(1, 10)}")
                else:
                    value = Decimal(random.choice((5, 10, 25)))
                match random.randint(1, 7):
                    case 1 | 2 | 3:
                        product = self.session.scalars(
                            select(models.Product)
                            .where(models.Product.created_by_id == restaurant.created_by_id)
                        ).first()
                        use_restaurant = random.randint(1, 4) == 1
                        use_quantity_break = random.randint(1, 5) == 1

                        if product is None:
                            continue

                        voucher = make_generic_voucher(f"{product.name} Flash Sales {i}", f"{value} off any purchases with {product.name}" + (f" in {restaurant.name}" if use_restaurant else ""), restaurant.created_by_id)
                        price = make_generic_price(voucher, value)
                        price.product = product
                        if use_restaurant:
                            price.restaurant = restaurant
                        if use_quantity_break:
                            from_quantity = random.randint(2, 4)
                            price.quantity_break = models.QuantityBreak(
                                from_quantity=from_quantity
                            )
                    case 4:
                        voucher = make_generic_voucher(f"{restaurant.name} Offer {i}", f"{value} off shopping in {restaurant.name}", restaurant.created_by_id)
                        price = make_generic_price(voucher, value)
                        price.restaurant = restaurant
                    case 5:
                        from_amount = Decimal(random.randint(20, 80))
                        use_restaurant = random.randint(1, 4) == 1
                        voucher = make_generic_voucher(f"Mass Purchase Sale {i}", f"{value} off any purchases with more than ${from_amount}" + (f" in {restaurant.name}" if use_restaurant else ""), restaurant.created_by_id)
                        price = make_generic_price(voucher, value)
                        price.order_value = models.OrderValue(
                            from_amount=from_amount
                        )
                        if use_restaurant:
                            price.restaurant = restaurant
                    case _:
                        product_feature = self.session.scalars(
                            select(models.ProductFeature)
                            .where(models.ProductFeature.created_by_id == restaurant.created_by_id)
                        ).first()
                        use_restaurant = random.randint(1, 4) == 1

                        if product_feature is None:
                            continue

                        voucher = make_generic_voucher(f"{product_feature.name} Discount {i}", f"{value} off any purchases with {product_feature.name}" + (f" in {restaurant.name}" if use_restaurant else ""), restaurant.created_by_id)
                        price = make_generic_price(voucher, value)
                        price.product_feature = product_feature
                        if use_restaurant:
                            price.restaurant = restaurant

                voucher.priced.add(price)  # noqa
                distribute_randomly(voucher)
                self.session.add(voucher)

        self.session.commit()

    def seed_orders(self) -> None:
        for member in self.tables[models.Member]:
            days = pl.date_range(start=member.created_at, end=self.now, interval="1d", eager=True)
            for day in days.sample(fraction=1 / 3).sort():
                restaurant = random.choice(self.tables[models.Restaurant])
                day = self.faker.date_time_between(
                    start_date=day.replace(hour=0, minute=0, second=0) + restaurant.opening_hour,
                    end_date=day.replace(hour=0, minute=0, second=0) + restaurant.closing_hour,
                )

                orders = self._create_order(member, restaurant, day)
                member.orders.add(orders)

        self.session.commit()
