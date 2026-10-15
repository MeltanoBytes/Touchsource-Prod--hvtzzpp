-- Fails if a closed ownership period starts after it ends.

select
    property_ownership_id,
    property_name,
    effective_start,
    effective_end
from {{ ref('dim__property_ownership') }}
where effective_end is not null
    and effective_start > effective_end
