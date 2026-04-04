from datetime import datetime, timedelta

import re
import factory.fuzzy

from online_food_ordering_system_seeder import models, common

START_DATE = datetime(2026, 1, 1)


class Base(factory.alchemy.SQLAlchemyModelFactory):
    class Meta:
        abstract = True
        sqlalchemy_session = common.Session


class AddressFactory(Base):
    class Meta:
        model = models.Address


class MemberFactory(Base):
    class Meta:
        model = models.Member
        exclude = ("profile", "address_s")

    profile = factory.Faker("profile")
    address_s = factory.LazyAttribute(lambda o: o.profile["address"].replace("\n", ", "))

    username = factory.LazyAttribute(lambda o: o.profile["username"])
    email = factory.LazyAttribute(lambda o: o.profile["mail"])
    created_at = factory.fuzzy.FuzzyNaiveDateTime(start_dt=START_DATE)


class MemberAddressFactory(Base):
    class Meta:
        model = models.MemberAddress

    member = factory.SubFactory(MemberFactory)
    address = factory.SubFactory(AddressFactory)


class MemberWithAddressFactory(MemberFactory):
    addresses = factory.RelatedFactory(
        MemberAddressFactory,
        factory_related_name="member",
        address=factory.SubFactory(
            AddressFactory,
            name=factory.LazyAttribute(lambda o: o.factory_parent.factory_parent.profile["name"]),
            contact_no=factory.Faker("basic_phone_number"),
            address_1=factory.LazyAttribute(lambda o: o.factory_parent.factory_parent.address_s.split(", ")[0]),
            city=factory.LazyAttribute(lambda o: o.factory_parent.factory_parent.address_s.split(", ")[1]),
            state=factory.LazyAttribute(lambda o: "".join(
                re.findall(r"\D+", o.factory_parent.factory_parent.address_s.split(", ")[-1]))),
            postcode=factory.LazyAttribute(lambda o: "".join(
                re.findall(r"\d+", o.factory_parent.factory_parent.address_s.split(", ")[-1])) or 10100),
            country=factory.Faker("current_country")
        )
    )


class RestaurantFactory(Base):
    class Meta:
        model = models.Restaurant
        exclude = ("opening_closing", "address_faker", "address_s")

    opening_closing = factory.fuzzy.FuzzyChoice((
        (timedelta(hours=8, seconds=0), timedelta(hours=22, seconds=0)),
        (timedelta(hours=9, seconds=0), timedelta(hours=21, seconds=0)),
        (timedelta(hours=10, seconds=0), timedelta(hours=22, seconds=0)),
        (timedelta(hours=10, seconds=0), timedelta(hours=20, seconds=0)),
    ))
    address_faker = factory.Faker("address")
    address_s = factory.LazyAttribute(lambda o: o.address_faker.replace("\n", ", "))

    code = factory.Faker("company")
    introduction_date = factory.fuzzy.FuzzyDate(start_date=START_DATE.date())
    opening_hour = factory.LazyAttribute(lambda o: o.opening_closing[0])
    closing_hour = factory.LazyAttribute(lambda o: o.opening_closing[1])

    address = factory.SubFactory(
        AddressFactory,
        name=factory.LazyAttribute(lambda o: o.factory_parent.code),
        contact_no=factory.Faker("basic_phone_number"),
        address_1=factory.LazyAttribute(lambda o: o.factory_parent.address_s.split(", ")[0]),
        city=factory.LazyAttribute(lambda o: o.factory_parent.address_s.split(", ")[1]),
        state=factory.LazyAttribute(lambda o: "".join(
            re.findall(r"\D+", o.factory_parent.address_s.split(", ")[-1]))),
        postcode=factory.LazyAttribute(lambda o: "".join(
            re.findall(r"\d+", o.factory_parent.address_s.split(", ")[-1])) or 10100),
        country=factory.Faker("current_country")
    )
