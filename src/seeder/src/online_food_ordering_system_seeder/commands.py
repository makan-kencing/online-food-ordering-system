import random
from datetime import datetime, timedelta
from typing import Sequence

import polars as pl
from faker import Faker
from polars import Decimal
from sqlalchemy import select
from sqlalchemy.orm import Session, contains_eager, joinedload
from sqlalchemy.sql import expression, func, or_

from online_food_ordering_system_seeder import models


class Seeder:
    def __init__(self, session: Session):
        self.session = session
        self.faker = Faker()

        self.now = datetime.now()

    def __enter__[T](self):
        self.session.__enter__()
        self.tables: dict[type[T], Sequence[T]] = {
            models.Member: self.session.scalars(select(models.Member)
                                                .options(contains_eager(models.Member.addresses),
                                                         contains_eager(models.Member.subscriptions),
                                                         contains_eager(models.Member.orders))
                                                .join(models.Member.addresses)
                                                .join(models.Member.subscriptions)
                                                .join(models.Member.orders)).unique().all(),
            models.PaymentMethod: self.session.scalars(select(models.PaymentMethod)).all(),
            models.Membership: self.session.scalars(select(models.Membership)).all(),
            models.Restaurant: self.session.scalars(select(models.Restaurant)).all(),
            models.DeliveryVendor: self.session.scalars(select(models.DeliveryVendor)).all(),
            models.Voucher: self.session.scalars(select(models.Voucher)
                                                 .options(contains_eager(models.Voucher.distributed_to))
                                                 .join(models.Voucher.distributed_to)).all()
        }
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
        price: models.PriceComponent = self.session.scalars(stmt).one()
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
        price: models.PriceComponent = self.session.scalars(stmt).one()
        assert price.amount is not None
        return price.amount

    def _add_order_item_surcharges(self, order_item: models.OrderItem) -> None:
        prices: Sequence[models.PriceComponent] = self.session.scalars(
            select(models.PriceComponent)
            .options(joinedload(models.PriceComponent.quantity_break))
            .where(or_(
                models.PriceComponent.product_id == order_item.product.id,
                models.PriceComponent.product_id.is_(expression.Null())))
            .where(models.PriceComponent.order_value_id.is_(expression.Null()))
            .where(models.PriceComponent.vendor_id.is_(expression.Null()))
            .where(models.PriceComponent.from_date < self.now)
            .where(func.coalesce(models.PriceComponent.thru_date, func.now()) > self.now)
        ).all()
        adjustment_type = models.OrderItemAdjustment.AdjustmentType.SURCHARGE
        for price in prices:
            if price.product_category_id is not None:
                continue

            if price.quantity_break is not None:
                quantity_break = price.quantity_break
                if quantity_break.from_quantity > order_item.quantity:
                    continue
                if quantity_break.thru_quantity is not None and quantity_break.thru_quantity < order_item.quantity:
                    continue

            if price.product_id is not None:
                order = order_item.order
                if price.restaurant_id is not None:
                    if order.restaurant_id != price.restaurant_id:
                        continue

                if price.membership_id is not None:
                    if order.member is None:
                        continue
                    subscription = order.member.get_current_subscription(self.now)
                    if subscription is None:
                        continue
                    if subscription.membership_id != price.membership_id:
                        continue

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
        prices: Sequence[models.PriceComponent] = self.session.scalars(
            select(models.PriceComponent)
            .options(joinedload(models.PriceComponent.quantity_break))
            .where(or_(
                models.PriceComponent.product_id == order_item_feature.order_item.product.id,
                models.PriceComponent.product_id.is_(expression.Null())))
            .where(models.PriceComponent.product_feature_id == order_item_feature.product_feature_id)
            .where(models.PriceComponent.order_value_id.is_(expression.Null()))
            .where(models.PriceComponent.vendor_id.is_(expression.Null()))
            .where(models.PriceComponent.from_date < self.now)
            .where(func.coalesce(models.PriceComponent.thru_date, func.now()) > self.now)
        ).all()
        adjustment_type = models.OrderItemAdjustment.AdjustmentType.SURCHARGE
        for price in prices:
            if price.product_category_id is not None:
                continue

            if price.quantity_break is not None:
                quantity_break = price.quantity_break
                if quantity_break.from_quantity > order_item_feature.quantity:
                    continue
                if quantity_break.thru_quantity is not None and quantity_break.thru_quantity < order_item_feature.quantity:
                    continue

            if price.product_id is not None:
                order = order_item_feature.order_item.order
                if price.restaurant_id is not None:
                    if order.restaurant_id != price.restaurant_id:
                        continue

                if price.membership_id is not None:
                    if order.member is None:
                        continue
                    subscription = order.member.get_current_subscription(self.now)
                    if subscription is None:
                        continue
                    if subscription.membership_id != price.membership_id:
                        continue

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
        prices: Sequence[models.PriceComponent] = self.session.scalars(
            select(models.PriceComponent)
            .options(joinedload(models.PriceComponent.order_value))
            .where(models.PriceComponent.product_id.is_(expression.Null()))
            .where(models.PriceComponent.product_feature_id.is_(expression.Null()))
            .where(models.PriceComponent.product_category_id.is_(expression.Null()))
            .where(models.PriceComponent.quantity_break_id.is_(expression.Null()))
            .where(models.PriceComponent.from_date < self.now)
            .where(func.coalesce(models.PriceComponent.thru_date, func.now()) > self.now)
        ).all()
        adjustment_type = models.OrderItemAdjustment.AdjustmentType.SURCHARGE
        for price in prices:
            if price.order_value is not None:
                order_value = price.order_value
                subtotal = order.subtotal
                if order_value.from_amount > subtotal:
                    continue
                if order_value.thru_amount is not None and order_value.thru_amount < subtotal:
                    continue

            if price.restaurant_id is not None:
                if order.restaurant_id != price.restaurant_id:
                    continue

            if price.membership_id is not None:
                if order.member is None:
                    continue
                subscription = order.member.get_current_subscription(self.now)
                if subscription is None:
                    continue
                if subscription.membership_id != price.membership_id:
                    continue

            if price.vendor_id is not None:
                if order.delivery is None:
                    continue
                if order.delivery.vendor_id != price.vendor_id:
                    continue

            if price.price_type == models.PriceComponent.PriceType.DISCOUNT:
                adjustment_type = models.OrderItemAdjustment.AdjustmentType.DISCOUNT

            order.adjustments.add(models.OrderItemAdjustment(
                order=order,
                adjustment_type=adjustment_type,
                amount=price.amount,
                percentage=price.percentage
            ))

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

        self._add_order_surcharges(order)
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
            invoice.vouchers.add(models.VoucherRedemption(
                voucher_distribution=voucher,
                invoice=invoice
            ))
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
        members = self.tables[models.Member]
        for voucher in self.tables[models.Voucher]:
            for member in random.choices(members, k=len(members) // 10):
                voucher.distributed_to.add(models.VoucherDistribution(
                    voucher_id=voucher.id,
                    member_id=member.id
                ))

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
