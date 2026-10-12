WITH page_stats AS (
    SELECT
        d_created.d_date_sk AS date_sk,
        COUNT(DISTINCT wp_c.wp_web_page_id) AS pages_created,
        COUNT(DISTINCT wp_a.wp_web_page_id) AS pages_accessed
    FROM date_dim d_created
    LEFT JOIN web_page wp_c
        ON wp_c.wp_creation_date_sk = d_created.d_date_sk
    LEFT JOIN web_page wp_a
        ON wp_a.wp_access_date_sk = d_created.d_date_sk
    GROUP BY d_created.d_date_sk
),
store_return_stats AS (
    SELECT
        sr.sr_store_sk,
        d_return.d_date_sk,
        d_return.d_date,
        d_return.d_year,
        hd.hd_buy_potential,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS num_returns,
        AVG(sr.sr_return_amt) AS avg_return_amount,
        MIN(sr.sr_return_amt) AS min_return_amount,
        MAX(sr.sr_return_amt) AS max_return_amount,
        SUM(sr.sr_store_credit) AS total_store_credit,
        SUM(sr.sr_fee) AS total_fee,
        SUM(sr.sr_return_tax) AS total_return_tax,
        SUM(sr.sr_return_ship_cost) AS total_ship_cost
    FROM store_returns sr
    JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY
        sr.sr_store_sk,
        d_return.d_date_sk,
        d_return.d_date,
        d_return.d_year,
        hd.hd_buy_potential
)
SELECT
    s.s_store_id,
    s.s_store_name,
    r.d_date,
    r.d_year,
    r.hd_buy_potential,
    r.total_net_loss,
    r.num_returns,
    r.avg_return_amount,
    r.min_return_amount,
    r.max_return_amount,
    r.total_store_credit,
    r.total_fee,
    r.total_return_tax,
    r.total_ship_cost,
    ps.pages_created,
    ps.pages_accessed,
    RANK() OVER (PARTITION BY r.d_year ORDER BY r.total_net_loss DESC) AS net_loss_rank_year,
    CASE
        WHEN r.total_net_loss > 10000 THEN 'HIGH'
        WHEN r.total_net_loss > 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS net_loss_category,
    DATE_DIFF('day', d_closed.d_date, r.d_date) AS days_since_store_closed
FROM store_return_stats r
JOIN store s
    ON r.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN page_stats ps
    ON r.d_date_sk = ps.date_sk
WHERE r.total_net_loss > 0
ORDER BY r.d_year, net_loss_rank_year
LIMIT 100
