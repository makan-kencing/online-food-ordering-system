import logging

import click
from sqlalchemy import create_engine

from online_food_ordering_system_seeder import common, factories
from online_food_ordering_system_seeder.commands import Seeder

logger = logging.getLogger(__name__)


@click.command()
@click.option("--host", default="localhost", help="The target database host")
@click.option("--port", default=1521, help="The target database port")
@click.option("--sid", default="FREEPDB1", help="The target database service id")
@click.option("--username", help="Login username")
@click.password_option("--password", help="Login password")
def seed(host: str, port: int, sid: str, username: str, password: str) -> None:
    engine = create_engine(
        f"oracle+oracledb://{username}:{password}@{host}:{port}?service_name={sid}"
    )
    common.Session.configure(bind=engine)
    session = common.Session()
    with Seeder(session) as seeder:
        factories.MemberWithAddressFactory.create_batch(200)
        seeder.refresh_cache()
        seeder.seed_memberships()
        seeder.refresh_cache()
        seeder.seed_vouchers()
        seeder.refresh_cache()
        seeder.seed_prices()
        seeder.refresh_cache()
        seeder.seed_orders()


if __name__ == "__main__":
    seed()
