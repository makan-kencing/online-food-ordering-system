import factory.fuzzy
from datetime import datetime

from online_food_ordering_system_seeder import models, common


class Base(factory.alchemy.SQLAlchemyModelFactory):
    class Meta:
        abstract = True
        sqlalchemy_session = common.Session


class MemberFactory(Base):
    class Meta:
        model = models.Member
        exclude = ("profile",)

    profile = factory.Faker("simple_profile")

    id = factory.Sequence(lambda n: n)
    username = factory.LazyAttribute(lambda o: o.profile["username"])
    email = factory.LazyAttribute(lambda o: o.profile["mail"])
    created_at = factory.fuzzy.FuzzyNaiveDateTime(start_dt=datetime(2026, 1, 1))

