WITH filtered_returns AS (
    SELECT
        s.s_store_name,
        s.s_store_id,
        t.t_shift,
        sr.sr_net_loss,
        sr.sr_refunded_cash,
        hd.hd_buy_potential,
        -- extract the alphabetic code from hd_buy_potential (e.g., "AB" from "AB123")
        regexp_extract(hd.hd_buy_potential, '([A-Z]+)', 1) AS buy_potential_code,
        -- build a concatenated key for store‑shift
        concat(s.s_store_id, '_', t.t_shift) AS store_shift_key
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE
        -- keep only stores whose name contains the word "Mart"
        s.s_store_name LIKE '%Mart%'
        -- keep only shifts "first" or "second"
        AND t.t_shift IN ('first', 'second')
        -- keep only household buy‑potential values that are all caps letters (e.g., "HIGH", "MED")
        AND regexp_like(hd.hd_buy_potential, '^[A-Z]+$')
        -- example of substring predicate: first 5 characters of store name start with "Super"
        AND substring(s.s_store_name, 1, 5) = 'Super'
), aggregated AS (
    SELECT
        s_store_name,
        s_store_id,
        t_shift,
        buy_potential_code,
        store_shift_key,
        sum(sr_net_loss) AS total_net_loss,
        avg(sr_refunded_cash) AS avg_refunded_cash
    FROM filtered_returns
    GROUP BY
        s_store_name,
        s_store_id,
        t_shift,
        buy_potential_code,
        store_shift_key
    HAVING sum(sr_net_loss) > 5000
)
SELECT
    s_store_name,
    s_store_id,
    t_shift,
    buy_potential_code,
    store_shift_key,
    total_net_loss,
    avg_refunded_cash
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
