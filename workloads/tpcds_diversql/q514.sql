-- Goal: Identify top‑selling items in 2001 that belong to a specific item description pattern and email‑promoted campaigns, 
-- limited to stores matched by an INTERSECT of store‑name and sales‑quantity criteria.  
-- The query demonstrates string functions (regexp_like, substring, concat), a FULL OUTER JOIN, an INTERSECT CTE, an EXISTS subquery, 
-- aggregation, a global ROW_NUMBER, ordering and a LIMIT.
WITH intersect_keys AS (
    SELECT s.s_store_sk
    FROM store s
    WHERE s.s_store_name LIKE '%Market%'
    INTERSECT
    SELECT ss.ss_store_sk
    FROM store_sales ss
    WHERE ss.ss_quantity > 5
),
filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_hdemo_sk,
        ss.ss_net_paid,
        d.d_year,
        i.i_item_desc,
        p.p_promo_name,
        s.s_store_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '[A-Za-z]{3}[0-9]{2}')
      AND p.p_channel_email = 'Y'
      AND ss.ss_store_sk IN (SELECT s_store_sk FROM intersect_keys)
),
full_sp AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        p.p_promo_sk,
        p.p_promo_name
    FROM store s
    FULL OUTER JOIN promotion p ON TRUE
)
SELECT
    CONCAT(
        COALESCE(fs.s_store_name, fsp.s_store_name, 'Unknown Store'),
        ' - ',
        COALESCE(fs.p_promo_name, fsp.p_promo_name, 'No Promo')
    ) AS store_promo,
    SUBSTRING(fs.i_item_desc, 1, 12) AS short_item_desc,
    SUM(fs.ss_net_paid) AS total_net_paid,
    ROW_NUMBER() OVER (ORDER BY SUM(fs.ss_net_paid) DESC) AS rn
FROM filtered_sales fs
LEFT JOIN household_demographics hd ON fs.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN full_sp fsp ON fs.ss_store_sk = fsp.s_store_sk AND fs.ss_promo_sk = fsp.p_promo_sk
WHERE EXISTS (
    SELECT 1
    FROM household_demographics hd2
    WHERE hd2.hd_demo_sk = fs.ss_hdemo_sk
      AND hd2.hd_buy_potential = '5001-10000'
)
GROUP BY
    CONCAT(
        COALESCE(fs.s_store_name, fsp.s_store_name, 'Unknown Store'),
        ' - ',
        COALESCE(fs.p_promo_name, fsp.p_promo_name, 'No Promo')
    ),
    SUBSTRING(fs.i_item_desc, 1, 12)
ORDER BY rn
LIMIT 100
