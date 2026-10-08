-- Fails if two ownership periods for the same property overlap (inclusive).
-- Overlaps would let a single transaction date match multiple ownership rows,
-- duplicating attributed revenue. Also catches duplicate (property_name, effective_start).

with periods as (
    select
        property_ownership_id,
        property_name,
        effective_start,
        coalesce(effective_end, date '9999-12-31') as effective_end
    from {{ ref('dim__property_ownership') }}
)

select
    a.property_name,
    a.property_ownership_id as id_a,
    b.property_ownership_id as id_b
from periods a
join periods b
    on a.property_name = b.property_name
    and a.property_ownership_id < b.property_ownership_id
    and a.effective_start <= b.effective_end
    and b.effective_start <= a.effective_end
