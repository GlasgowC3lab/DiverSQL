-- Goal: Identify recent catalog pages together with their associated store, web page and inventory activity, 
-- compute running inventory quantities, previous start dates, next end dates, and total start‑date inventory per catalog page.
-- The query joins all five selected tables using the allowed surrogate‑key relationships, re‑uses several tables under different aliases to create at least nine join clauses, samples the inventory table, and returns the top‑5 rows per catalog page.
WITH filtered AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        s.s_store_name,
        wp.wp_type,
        d_start.d_year AS start_year,
        d_end.d_year   AS end_year,
        d_creation.d_year AS creation_year,
        d_access.d_year   AS access_year,
        i.inv_quantity_on_hand,
        i2.inv_quantity_on_hand AS inv_qty_end,
        LAG(d_start.d_date) OVER (PARTITION BY cp.cp_catalog_page_id ORDER BY d_start.d_date)               AS prev_start_date,
        LEAD(d_end.d_date) OVER (PARTITION BY cp.cp_catalog_page_id ORDER BY d_start.d_date)               AS next_end_date,
        SUM(i.inv_quantity_on_hand) OVER (PARTITION BY cp.cp_catalog_page_id ORDER BY d_start.d_date ROWS UNBOUNDED PRECEDING) AS running_qty,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_catalog_page_id ORDER BY d_start.d_date DESC)               AS rn,
        (
            SELECT SUM(ii.inv_quantity_on_hand)
            FROM inventory ii
            JOIN date_dim ddi ON ii.inv_date_sk = ddi.d_date_sk
            WHERE ddi.d_date_sk = cp.cp_start_date_sk
        ) AS total_start_qty
    FROM catalog_page cp
    -- 1. cp start date
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    -- 2. cp end date
    JOIN date_dim d_end   ON cp.cp_end_date_sk   = d_end.d_date_sk
    -- 3. store closed date linked to the same end date
    JOIN store s          ON s.s_closed_date_sk = d_end.d_date_sk
    -- 4. web_page creation linked to the catalog start date
    JOIN web_page wp      ON wp.wp_creation_date_sk = d_start.d_date_sk
    -- 5. extra join to date_dim for the same creation key (different alias)
    JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
    -- 6. web_page access date
    JOIN date_dim d_access   ON wp.wp_access_date_sk = d_access.d_date_sk
    -- 7. inventory sampled and linked to the start date
    JOIN inventory i TABLESAMPLE BERNOULLI (5) ON i.inv_date_sk = d_start.d_date_sk
    -- 8. a second inventory alias linked to the end date
    JOIN inventory i2 ON i2.inv_date_sk = d_end.d_date_sk
    -- 9. an additional store‑date join using a separate date_dim alias
    JOIN date_dim d_store_start ON s.s_closed_date_sk = d_store_start.d_date_sk
)
SELECT *
FROM filtered
WHERE rn <= 5
ORDER BY cp_catalog_page_id, start_year DESC
LIMIT 100
