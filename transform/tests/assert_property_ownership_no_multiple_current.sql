-- Fails if any property has more than one open (current) ownership period.
-- A property must not have two concurrent "current" owners.

select
    property_name,
    count(*) as current_rows
from {{ ref('dim__property_ownership') }}
where is_current
group by property_name
having count(*) > 1
