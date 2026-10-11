"""simulacion propuestas

Revision ID: a1b2c3d4e5f6
Revises: 5546ec73abc4
Create Date: 2026-10-10 18:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "a1b2c3d4e5f6"
down_revision: Union[str, Sequence[str], None] = "5546ec73abc4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    with op.batch_alter_table("necesidades") as batch:
        batch.add_column(sa.Column("visible_desde", sa.DateTime(), nullable=True))
        batch.add_column(
            sa.Column("simulacion_estudiante_id", sa.Integer(), nullable=True)
        )
        batch.create_foreign_key(
            "fk_necesidades_simulacion_usuario",
            "usuarios",
            ["simulacion_estudiante_id"],
            ["id"],
        )
    with op.batch_alter_table("perfiles_estudiante") as batch:
        batch.add_column(sa.Column("simulacion_inicio", sa.DateTime(), nullable=True))
        batch.add_column(sa.Column("simulacion_intervalo", sa.Integer(), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    with op.batch_alter_table("perfiles_estudiante") as batch:
        batch.drop_column("simulacion_intervalo")
        batch.drop_column("simulacion_inicio")
    with op.batch_alter_table("necesidades") as batch:
        batch.drop_constraint("fk_necesidades_simulacion_usuario", type_="foreignkey")
        batch.drop_column("simulacion_estudiante_id")
        batch.drop_column("visible_desde")
