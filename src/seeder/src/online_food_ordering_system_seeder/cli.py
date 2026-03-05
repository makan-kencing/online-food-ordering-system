import logging

import click
from sqlalchemy.ext.asyncio import create_async_engine

from online_food_ordering_system_seeder import common

logger = logging.getLogger(__name__)


@click.command()
@click.option("--host", help="The target database host")
@click.option("--port", help="The target database port")
@click.option("--sid", default="FREEPDB1", help="The target database service id")
@click.option("--username", help="Login username")
@click.option("--password", help="Login password")
def seed(host: str, port: int, sid: str, username: str, password: str) -> None:
    engine = create_async_engine(
        "oracle+oracledb://@",
        connect_args={
            "user": username,
            "password": password,
            "dsn": f"{host}:{port}/{sid}"
        }
    )
    common.Session.configure(bind=engine)


if __name__ == "__main__":
    seed()
