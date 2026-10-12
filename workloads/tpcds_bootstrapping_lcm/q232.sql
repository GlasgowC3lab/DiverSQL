WITH catalog_daily AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk
),
web_daily AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        SUM(wr.wr_net_loss) AS total_web_net_loss
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
),
promotion_daily AS (
    SELECT
        p.p_start_date_sk AS date_sk,
        SUM(p.p_cost) AS total_promotion_cost,
        AVG(p.p_response_target) AS avg_promotion_response_target
    FROM promotion p
    WHERE p.p_end_date_sk >= p.p_start_date_sk
    GROUP BY p.p_start_date_sk
),
store_daily AS (
    SELECT
        s.s_closed_date_sk AS date_sk,
        COUNT(DISTINCT s.s_store_sk) AS stores_closed
    FROM store s
    GROUP BY s.s_closed_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    COALESCE(cd.catalog_return_orders, 0) AS catalog_return_orders,
    COALESCE(wd.web_return_orders, 0) AS web_return_orders,
    COALESCE(cd.total_catalog_return_amount, 0) + COALESCE(wd.total_web_return_amount, 0) AS total_return_amount,
    COALESCE(cd.total_catalog_net_loss, 0) + COALESCE(wd.total_web_net_loss, 0) AS total_net_loss,
    COALESCE(pd.total_promotion_cost, 0) AS total_promotion_cost,
    COALESCE(sd.stores_closed, 0) AS stores_closed,
    CASE
        WHEN COALESCE(pd.total_promotion_cost, 0) = 0 THEN NULL
        ELSE (COALESCE(cd.total_catalog_return_amount, 0) + COALESCE(wd.total_web_return_amount, 0)) / pd.total_promotion_cost
    END AS return_to_promo_ratio,
    RANK() OVER (ORDER BY (COALESCE(cd.total_catalog_net_loss, 0) + COALESCE(wd.total_web_net_loss, 0)) DESC) AS net_loss_rank,
    COALESCE(pd.avg_promotion_response_target, 0) AS avg_promotion_response_target
FROM date_dim d
LEFT JOIN catalog_daily cd ON cd.date_sk = d.d_date_sk
LEFT JOIN web_daily wd ON wd.date_sk = d.d_date_sk
LEFT JOIN promotion_daily pd ON pd.date_sk = d.d_date_sk
LEFT JOIN store_daily sd ON sd.date_sk = d.d_date_sk
WHERE d.d_date IS NOT NULL
ORDER BY total_net_loss DESC
LIMIT 100
