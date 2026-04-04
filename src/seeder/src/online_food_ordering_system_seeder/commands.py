import random
from datetime import datetime, timedelta
from typing import Sequence

import polars as pl
from faker import Faker
from sqlalchemy import select, func
from sqlalchemy.orm import Session, aliased, contains_eager

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
                                                         contains_eager(models.Member.subscriptions))
                                                .join(models.Member.addresses)
                                                .join(models.Member.subscriptions)).unique().all(),
            models.PaymentMethod: self.session.scalars(select(models.PaymentMethod)).all(),
            models.Membership: self.session.scalars(select(models.Membership)).all(),
            models.Restaurant: self.session.scalars(select(models.Restaurant)).all(),
            models.DeliveryVendor: self.session.scalars(select(models.DeliveryVendor)).all(),
            models.Voucher: self.session.scalars(select(models.Voucher)).all()
        }
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.session.commit()
        self.session.__exit__(exc_type, exc_val, exc_tb)

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

        product_priced_alias = aliased(models.PriceComponent)
        product_feature_priced_alias = aliased(models.PriceComponent)
        stmt = select(models.MenuItem) \
            .options(contains_eager(models.MenuItem.product)
                     .contains_eager(models.Product.priced, product_priced_alias),
                     contains_eager(models.MenuItem.product)
                     .contains_eager(models.Product.attributes)
                     .contains_eager(models.ProductAttribute.product_feature_group)
                     .contains_eager(models.ProductFeatureGroup.fields)
                     .contains_eager(models.ProductFeatureGroupField.product_feature)
                     .contains_eager(models.ProductFeature.priced, product_feature_priced_alias)) \
            .where(models.MenuItem.restaurant_id == restaurant.id) \
            .join(models.MenuItem.product) \
            .where(order_time > models.Product.introduction_date) \
            .join(product_priced_alias, models.Product.priced) \
            .where(product_priced_alias.from_date >= order_time) \
            .where(order_time < func.coalesce(product_priced_alias.from_date, func.current_timestamp())) \
            .join(models.Product.attributes) \
            .join(models.ProductAttribute.product_feature_group) \
            .join(models.ProductFeatureGroup.fields) \
            .join(models.ProductFeatureGroupField.product_feature) \
            .join(product_feature_priced_alias, models.ProductFeature.priced) \
            .where(product_feature_priced_alias.from_date >= order_time) \
            .where(order_time < func.coalesce(product_feature_priced_alias.from_date, func.current_timestamp()))
        menu_items = self.session.scalars(stmt).all()
        for menu_item in random.choices(menu_items, k=random.randint(1, len(menu_items) // 3)):
            product = menu_item.product
            quantity = random.randint(1, 3)

            order_item = models.OrderItem(
                order=order,
                product_id=product.id,
                quantity=quantity,
                unit_price=product.base_price.amount
            )

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
                        product_feature_id=product_feature.id,
                        order_item=order_item,
                        quantity=quantity,
                        unit_price=product_feature.base_price.amount
                    )
                    order_item.features.add(order_item_feature)

            order.items.add(order_item)

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
        for member in random.choices(members, k=len(members) // 10):
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
                member.subscriptions.add(models.SubscriptionPayment(
                    payment=payment,
                    monthly_subscription=subscription
                ))
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
