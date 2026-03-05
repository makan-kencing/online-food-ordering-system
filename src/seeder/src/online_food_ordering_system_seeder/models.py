from __future__ import annotations

from datetime import datetime, timedelta
from decimal import Decimal
from enum import Enum, auto
from typing import Any

from sqlalchemy import String, Numeric, DateTime, ForeignKey, Interval, Enum as SAEnum, JSON, PrimaryKeyConstraint, \
    UniqueConstraint
from sqlalchemy.inspection import inspect
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship
from sqlalchemy.orm.exc import DetachedInstanceError
from sqlalchemy.sql import func, expression

__all__ = (
    "Member",
)

VERY_SHORT_STRING = String(15)
SHORT_STRING = String(50)
LONG_STRING = String(200)
URL_STRING = String(2083)


class Base(DeclarativeBase):
    def __repr__(self) -> str:
        return self._repr(**{attr: getattr(self, attr) for attr in inspect(self.__class__).columns.keys()})

    def _repr(self, **fields: Any) -> str:
        """
        Helper for __repr__
        """
        field_strings = []
        at_least_one_attached_attribute = False
        for key, field in fields.items():
            try:
                field_strings.append(f'{key}={field!r}')
            except DetachedInstanceError:
                field_strings.append(f'{key}=DetachedInstanceError')
            else:
                at_least_one_attached_attribute = True
        if at_least_one_attached_attribute:
            return f"<{self.__class__.__name__}({','.join(field_strings)})>"
        return f"<{self.__class__.__name__} {id(self)}>"


class HasId:
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)


class HasNameAndDescription:
    name: Mapped[str] = mapped_column(SHORT_STRING)
    description: Mapped[str] = mapped_column(LONG_STRING)


class Address(Base, HasId):
    __tablename__ = "address"

    name: Mapped[str] = mapped_column(SHORT_STRING)
    contact_no: Mapped[str] = mapped_column(VERY_SHORT_STRING)
    address_1: Mapped[str] = mapped_column(SHORT_STRING)
    address_2: Mapped[str | None] = mapped_column(SHORT_STRING)
    address_3: Mapped[str | None] = mapped_column(SHORT_STRING)
    city: Mapped[str] = mapped_column(SHORT_STRING)
    state: Mapped[str] = mapped_column(SHORT_STRING)
    postcode: Mapped[str] = mapped_column(String(10))
    country: Mapped[str] = mapped_column(SHORT_STRING)

    member: Mapped[MemberAddress] = relationship(back_populates="address")
    restaurant: Mapped[Restaurant] = relationship(back_populates="restaurant")
    deliveries: Mapped[set[Delivery]] = relationship(back_populates="address")


class DeliveryVendor(Base, HasId, HasNameAndDescription):
    __tablename__ = "delivery_vendor"

    deliveries: Mapped[set[Delivery]] = relationship(back_populates="vendor")
    priced: Mapped[set[PriceComponent]] = relationship(back_populates="vendor")


class Member(Base, HasId):
    __tablename__ = "member"

    username: Mapped[str] = mapped_column(SHORT_STRING, unique=True)
    email: Mapped[str] = mapped_column(String(254), unique=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=False), server_default=func.utcnow())

    addresses: Mapped[set[MemberAddress]] = relationship(back_populates="member")
    orders: Mapped[set[Orders]] = relationship(back_populates="member")
    vouchers: Mapped[set[VoucherDistribution]] = relationship(back_populates="member")
    subscriptions: Mapped[set[MonthlySubscription]] = relationship(back_populates="member")


class Membership(Base, HasId, HasNameAndDescription):
    __tablename__ = "membership"

    price: Mapped[Decimal] = mapped_column(Numeric())

    subscribers: Mapped[set[MonthlySubscription]] = relationship(back_populates="membership")
    priced: Mapped[set[PriceComponent]] = relationship(back_populates="membership")


class MenuCategory(Base, HasId, HasNameAndDescription):
    __tablename__ = "menu_category"

    featured_on: Mapped[set[Menu]] = relationship(back_populates="category")


class OrderValue(Base, HasId):
    __tablename__ = "order_value"

    from_amount: Mapped[Decimal] = mapped_column(Numeric())
    thru_amount: Mapped[Decimal | None] = mapped_column(Numeric())

    priced: Mapped[set[PriceComponent]] = relationship(back_populates="order_value")


class PaymentMethod(Base, HasId, HasNameAndDescription):
    __tablename__ = "payment_method"

    payments: Mapped[set[Payment]] = relationship(back_populates="payment_method")


class Product(Base, HasId, HasNameAndDescription):
    __tablename__ = "product"

    code: Mapped[str] = mapped_column(String(10), unique=True)
    introduction_date: Mapped[datetime] = mapped_column(DateTime(timezone=False), server_default=func.utcnow())
    image_url: Mapped[str | None] = mapped_column(URL_STRING)

    categories: Mapped[set[ProductCategoryClassification]] = relationship(back_populates="product")
    featured_on: Mapped[set[Menu]] = relationship(back_populates="product")
    ordered: Mapped[set[OrderItem]] = relationship(back_populates="product")
    product_features: Mapped[set[ProductFeatureApplicability]] = relationship(back_populates="product")
    product_feature_interactions: Mapped[set[ProductFeatureInteraction]] = relationship(back_populates="product")
    priced: Mapped[set[PriceComponent]] = relationship(back_populates="product")


class ProductCategory(Base, HasId, HasNameAndDescription):
    __tablename__ = "product_category"

    products: Mapped[set[ProductCategoryClassification]] = relationship(back_populates="product_category")
    parent: Mapped[ProductCategoryHierarchy | None] = relationship(back_populates="parent_category")
    children: Mapped[set[ProductCategoryHierarchy]] = relationship(back_populates="child_category")
    priced: Mapped[set[PriceComponent]] = relationship(back_populates="product_category")


class ProductFeatureCategory(Base, HasId, HasNameAndDescription):
    __tablename__ = "product_feature_category"

    product_features: Mapped[set[ProductFeature]] = relationship(back_populates="category")


class QuantityBreak(Base, HasId):
    __tablename__ = "quantity_break"

    from_quantity: Mapped[int] = mapped_column()
    thru_quantity: Mapped[int | None] = mapped_column()

    priced: Mapped[set[PriceComponent]] = relationship(back_populates="quantity_break")


class Voucher(Base, HasId, HasNameAndDescription):
    __tablename__ = "voucher"

    usage_limit: Mapped[int | None] = mapped_column()
    from_date: Mapped[datetime] = mapped_column()
    thru_date: Mapped[datetime | None] = mapped_column()

    distributed_to: Mapped[set[VoucherDistribution]] = relationship(back_populates="voucher")
    priced: Mapped[set[PriceComponent]] = relationship(back_populates="voucher")


class MemberAddress(Base):
    __tablename__ = "member_address"

    member_id: Mapped[int] = mapped_column(ForeignKey("member.id"))
    address_id: Mapped[int] = mapped_column(ForeignKey("address.id"), unique=True)
    is_primary: Mapped[bool] = mapped_column(server_default=expression.false())

    member: Mapped[Member] = relationship(back_populates="addresses")
    address: Mapped[Address] = relationship(back_populates="member", single_parent=True)

    __table_args__ = (
        PrimaryKeyConstraint("member_id", "address_id"),
    )


class Orders(Base, HasId):
    class OrderType(Enum):
        DELIVERY = auto()
        PICKUP = auto()

    __tablename__ = "orders"

    member_id: Mapped[int] = mapped_column(ForeignKey("member.id"))
    ordered_at: Mapped[datetime] = mapped_column(DateTime(timezone=False), server_default=func.now())
    order_type: Mapped[OrderType] = mapped_column(SAEnum(OrderType))

    member: Mapped[Member] = relationship(back_populates="order")
    delivery: Mapped[Delivery | None] = relationship(back_populates="order")
    invoice: Mapped[Invoice | None] = relationship(back_populates="order")
    items: Mapped[set[OrderItem]] = relationship(back_populates="order")
    adjustments: Mapped[set[OrderItemAdjustment]] = relationship(back_populates="order")



class Payment(Base, HasId):
    __tablename__ = "payment"

    payment_method_id: Mapped[int] = mapped_column(ForeignKey("payment_method.id"))
    paid_at: Mapped[datetime] = mapped_column(DateTime(timezone=False), server_default=func.now)
    ref_no: Mapped[str] = mapped_column(LONG_STRING)
    amount: Mapped[Decimal] = mapped_column(Numeric())
    payment_method_data: Mapped[str] = mapped_column(JSON())

    payment_method: Mapped[PaymentMethod] = relationship(back_populates="payments")
    invoice: Mapped[Invoice | None] = relationship(back_populates="payment")
    subscriptions: Mapped[set[MonthlySubscription]] = relationship(back_populates="payment")


class ProductCategoryClassification(Base):
    __tablename__ = "product_category_classification"

    product_id: Mapped[int] = mapped_column(ForeignKey("product.id"))
    product_category_id: Mapped[int] = mapped_column(ForeignKey("product_category.id"))
    from_date: Mapped[datetime] = mapped_column(DateTime(timezone=False))
    thru_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=False))
    is_primary: Mapped[bool] = mapped_column(server_default=expression.false())

    product: Mapped[Product] = relationship(back_populates="categories")
    product_category: Mapped[ProductCategory] = relationship(back_populates="products")

    __table_args__ = (
        PrimaryKeyConstraint("product_id", "product_category_id"),
    )


class ProductCategoryHierarchy(Base):
    __tablename__ = "product_category_hierarchy"

    parent_category_id: Mapped[int] = mapped_column(ForeignKey("product_category.id"))
    child_category_id: Mapped[int] = mapped_column(ForeignKey("product_category.id"))

    parent_category: Mapped[ProductCategory] = relationship(back_populates="parent")
    child_category: Mapped[ProductCategory] = relationship(back_populates="children")

    __table_args__ = (
        PrimaryKeyConstraint("parent_category_id", "child_category_id"),
    )


class ProductFeature(Base, HasId, HasNameAndDescription):
    __tablename__ = "product_feature"

    category_id: Mapped[int] = mapped_column(ForeignKey("product_feature_category.id"))

    category: Mapped[ProductFeatureCategory] = relationship(back_populates="product_features")
    products: Mapped[set[ProductFeatureApplicability]] = relationship(back_populates="product_feature")
    interact_with: Mapped[set[ProductFeatureInteraction]] = relationship(back_populates="feature_a")
    interacted_by: Mapped[set[ProductFeatureInteraction]] = relationship(back_populates="feature_b")
    order_items: Mapped[set[OrderItem]] = relationship(back_populates="product_feature")
    priced: Mapped[set[PriceComponent]] = relationship(back_populates="product_feature")


class Restaurant(Base, HasId, HasNameAndDescription):
    __tablename__ = "restaurant"

    code: Mapped[str] = mapped_column(String(10), unique=True)
    introduction_date: Mapped[datetime] = mapped_column(DateTime(timezone=False), server_default=func.now())
    image_url: Mapped[str | None] = mapped_column(URL_STRING)
    opening_hour: Mapped[timedelta] = mapped_column(Interval(day_precision=0, second_precision=0))
    closing_hour: Mapped[timedelta] = mapped_column(Interval(day_precision=0, second_precision=0))
    is_temporarily_closed: Mapped[bool] = mapped_column(server_default=expression.false())
    address_id: Mapped[int] = mapped_column(ForeignKey("address.id"), unique=True)

    address: Mapped[Address] = relationship(back_populates="restaurant", single_parent=True)
    menu: Mapped[set[Menu]] = relationship(back_populates="restaurant")


class VoucherDistribution(Base, HasId):
    __tablename__ = "voucher_distribution"

    voucher_id: Mapped[int] = mapped_column(ForeignKey("voucher.id"))
    member_id: Mapped[int] = mapped_column(ForeignKey("member.id"))

    voucher: Mapped[Voucher] = relationship(back_populates="distributed_to")
    member: Mapped[Member] = relationship(back_populates="vouchers")
    redemption: Mapped[VoucherRedemption | None] = relationship(back_populates="voucher_distribution")

    __table_args__ = (
        UniqueConstraint("voucher_id", "member_id"),
    )


class Delivery(Base, HasId):
    __tablename__ = "delivery"

    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id"), unique=True)
    address_id: Mapped[int] = mapped_column(ForeignKey("address.id"))
    vendor_id: Mapped[int] = mapped_column(ForeignKey("delivery_vendor.id"))
    ordered_at: Mapped[datetime] = mapped_column(DateTime(timezone=False), server_default=func.now())
    estimated_arrive_at: Mapped[datetime] = mapped_column(DateTime(timezone=False))

    order: Mapped[Orders] = relationship(back_populates="delivery", single_parent=True)
    address: Mapped[Address] = relationship(back_populates="deliveries")
    vendor: Mapped[DeliveryVendor] = relationship(back_populates="deliveries")


class Invoice(Base, HasId):
    __tablename__ = "invoice"

    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id"), unique=True)
    payment_id: Mapped[int] = mapped_column(ForeignKey("payment.id"), unique=True)
    invoiced_at: Mapped[datetime] = mapped_column(DateTime(timezone=False), server_default=func.now())
    amount: Mapped[Decimal] = mapped_column(Numeric())

    order: Mapped[Orders] = relationship(back_populates="invoice", single_parent=True)
    payment: Mapped[Payment] = relationship(back_populates="invoice", single_parent=True)
    vouchers: Mapped[set[VoucherRedemption]] = relationship(back_populates="invoice")


class Menu(Base):
    __tablename__ = "menu"

    product_id: Mapped[int] = mapped_column(ForeignKey("product.id"))
    restaurant_id: Mapped[int] = mapped_column(ForeignKey("restaurant.id"))
    category_id: Mapped[int | None] = mapped_column(ForeignKey("menu_category.id"))
    is_unavailable: Mapped[bool] = mapped_column(server_default=expression.false())
    from_date: Mapped[datetime] = mapped_column(DateTime(timezone=False), server_default=func.now())
    thru_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=False))

    product: Mapped[Product] = relationship(back_populates="featured_on")
    restaurant: Mapped[Restaurant] = relationship(back_populates="menu")
    category: Mapped[MenuCategory | None] = relationship(back_populates="featured_on")

    __table_args__ = (
        PrimaryKeyConstraint("product_id", "restaurant_id"),
    )


class MonthlySubscription(Base, HasId):
    __tablename__ = "monthly_subscription"

    membership_id: Mapped[int] = mapped_column(ForeignKey("membership.id"))
    member_id: Mapped[int] = mapped_column(ForeignKey("member.id"))
    payment_id: Mapped[int] = mapped_column(ForeignKey("payment.id"))
    from_date: Mapped[datetime] = mapped_column(DateTime(timezone=False), server_default=func.now())
    thru_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=False))

    membership: Mapped[Membership] = relationship(back_populates="subscribers")
    member: Mapped[Member] = relationship(back_populates="subscriptions")
    payment: Mapped[Payment] = relationship(back_populates="subscriptions")


class OrderItem(Base, HasId):
    __tablename__ = "order_item"

    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id"))
    product_id: Mapped[int] = mapped_column(ForeignKey("product.id"))
    quantity: Mapped[int] = mapped_column()
    unit_price: Mapped[Decimal] = mapped_column(Numeric())
    remarks: Mapped[int | None] = mapped_column(SHORT_STRING)

    order: Mapped[Orders] = relationship(back_populates="items")
    product: Mapped[Product] = relationship(back_populates="ordered")
    adjustments: Mapped[set[OrderItemAdjustment]] = relationship(back_populates="order_item")
    features: Mapped[set[OrderItemFeature]] = relationship(back_populates="order_item")


class PriceComponent(Base, HasId):
    class PriceType(Enum):
        BASE = auto()
        DISCOUNT = auto()
        SURCHARGE = auto()

    __tablename__ = "price_component"

    price_type: Mapped[PriceType] = mapped_column(SAEnum(PriceType))
    from_date: Mapped[datetime] = mapped_column(DateTime(timezone=False), server_default=func.now())
    thru_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=False))
    description: Mapped[str] = mapped_column(LONG_STRING)
    amount: Mapped[Decimal | None] = mapped_column(Numeric())
    percentage: Mapped[Decimal | None] = mapped_column(Numeric(5, 4))
    product_id: Mapped[int | None] = mapped_column(ForeignKey("product.id"))
    product_feature_id: Mapped[int | None] = mapped_column(ForeignKey("product_feature.id"))
    product_category_id: Mapped[int | None] = mapped_column(ForeignKey("product_category.id"))
    quantity_break_id: Mapped[int | None] = mapped_column(ForeignKey("quantity_break.id"))
    order_value_id: Mapped[int | None] = mapped_column(ForeignKey("order_value.id"))
    membership_id: Mapped[int | None] = mapped_column(ForeignKey("membership.id"))
    voucher_id: Mapped[int | None] = mapped_column(ForeignKey("voucher.id"))
    vendor_id: Mapped[int | None] = mapped_column(ForeignKey("vendor.id"))

    product: Mapped[Product | None] = relationship(back_populates="priced")
    product_feature: Mapped[ProductFeature | None] = relationship(back_populates="priced")
    product_category: Mapped[ProductCategory | None] = relationship(back_populates="priced")
    quantity_break: Mapped[QuantityBreak | None] = relationship(back_populates="priced")
    order_value: Mapped[OrderValue | None] = relationship(back_populates="priced")
    membership: Mapped[Membership | None] = relationship(back_populates="priced")
    voucher: Mapped[Voucher | None] = relationship(back_populates="priced")
    vendor: Mapped[DeliveryVendor | None] = relationship(back_populates="priced")


class ProductFeatureApplicability(Base):
    class ApplicabilityType(Enum):
        REQUIRED = auto()
        STANDARD = auto()
        OPTIONAL = auto()
        SELECTABLE = auto()

    __tablename__ = "product_feature_applicability"

    product_id: Mapped[int] = mapped_column(ForeignKey("product.id"))
    product_feature_id: Mapped[int] = mapped_column(ForeignKey("product_feature.id"))
    feature_type: Mapped[ApplicabilityType] = mapped_column(SAEnum(ApplicabilityType))
    from_date: Mapped[datetime] = mapped_column(DateTime(timezone=False), server_default=func.now())
    thru_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=False))

    product: Mapped[Product] = relationship(back_populates="product_features")
    product_feature: Mapped[ProductFeature] = relationship(back_populates="products")

    __table_args__ = (
        PrimaryKeyConstraint("product_id", "product_feature_id"),
    )


class ProductFeatureInteraction(Base, HasId):
    class InteractionType(Enum):
        DEPENDENT = auto()
        INCOMPATIBLE = auto()

    __tablename__ = "product_feature_interaction"

    feature_a_id: Mapped[int] = mapped_column(ForeignKey("product_feature.id"))
    feature_b_id: Mapped[int] = mapped_column(ForeignKey("product_feature.id"))
    product_id: Mapped[int | None] = mapped_column(ForeignKey("product.id"))
    interaction_type: Mapped[InteractionType] = mapped_column(SAEnum(InteractionType))

    feature_a: Mapped[ProductFeature] = relationship(back_populates="interact_with")
    feature_b: Mapped[ProductFeature] = relationship(back_populates="interacted_by")
    product: Mapped[Product | None] = relationship(back_populates="product_feature_interactions")

    __table_args__ = (
        UniqueConstraint("feature_a_id", "feature_b_id", "product_id"),
    )


class OrderItemAdjustment(Base, HasId):
    class AdjustmentType(Enum):
        DISCOUNT = auto()
        SURCHARGE = auto()
        SALES_TAX = auto()
        SHIPPING = auto()
        FEE = auto()
        MISCELLANEOUS = auto()

    __tablename__ = "order_item_adjustment"

    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id"))
    order_item_id: Mapped[int | None] = mapped_column(ForeignKey("order_item.id"))
    adjustment_type: Mapped[AdjustmentType] = mapped_column(SAEnum(AdjustmentType))
    amount: Mapped[Decimal | None] = mapped_column(Numeric())
    percentage: Mapped[Decimal | None] = mapped_column(Numeric(5, 4))

    order: Mapped[Orders] = relationship(back_populates="adjustments")
    order_item: Mapped[OrderItem | None] = relationship(back_populates="adjustments")


class OrderItemFeature(Base):
    __tablename__ = "order_item_feature"

    product_feature_id: Mapped[int] = mapped_column(ForeignKey("product_feature.id"))
    order_item_id: Mapped[int] = mapped_column(ForeignKey("order_item.id"))
    quantity: Mapped[int] = mapped_column()
    unit_price: Mapped[Decimal] = mapped_column(Numeric())
    remarks: Mapped[int | None] = mapped_column(SHORT_STRING)

    product_feature: Mapped[ProductFeature] = relationship(back_populates="order_items")
    order_item: Mapped[OrderItem] = relationship(back_populates="")

    __table_args__ = (
        PrimaryKeyConstraint("product_feature_id", "order_item_id"),
    )


class VoucherRedemption(Base):
    __tablename__ = "voucher_redemption"

    voucher_distribution_id: Mapped[int] = mapped_column(ForeignKey("voucher_distribution.id"), unique=True)
    invoice_id: Mapped[int] = mapped_column(ForeignKey("invoice.id"))

    voucher_distribution: Mapped[VoucherDistribution] = relationship(back_populates="redemption", single_parent=True)
    invoice: Mapped[Invoice] = relationship(back_populates="vouchers")

    __table_args__ = (
        PrimaryKeyConstraint("voucher_distribution_id", "invoice_id"),
    )
