"""organizacion usuario_id

Revision ID: c3d4e5f6a7b8
Revises: b2c3d4e5f6a7
Create Date: 2026-10-10 20:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "c3d4e5f6a7b8"
down_revision: Union[str, Sequence[str], None] = "b2c3d4e5f6a7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    with op.batch_alter_table("organizaciones") as batch:
        batch.add_column(sa.Column("usuario_id", sa.Integer(), nullable=True))
        batch.create_foreign_key(
            "fk_organizaciones_usuario_id",
            "usuarios",
            ["usuario_id"],
            ["id"],
        )


def downgrade() -> None:
    """Downgrade schema."""
    with op.batch_alter_table("organizaciones") as batch:
        batch.drop_constraint("fk_organizaciones_usuario_id", type_="foreignkey")
        batch.drop_column("usuario_id")
