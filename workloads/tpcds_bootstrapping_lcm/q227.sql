WITH catalog_agg AS (
    SELECT cr_returned_date_sk AS d_date_sk,
           SUM(cr_net_loss) AS catalog_net_loss
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
),
web_agg AS (
    SELECT wr_returned_date_sk AS d_date_sk,
           SUM(wr_net_loss) AS web_net_loss
    FROM web_returns
    GROUP BY wr_returned_date_sk
),
sales_agg AS (
    SELECT ss_sold_date_sk AS d_date_sk,
           ss_store_sk,
           COUNT(*) AS sales_cnt,
           SUM(ss_net_profit) AS sales_net_profit,
           SUM(ss_quantity) AS total_quantity
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_store_sk
),
joined_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        COALESCE(sa.sales_cnt, 0) AS total_sales_tickets,
        COALESCE(sa.sales_net_profit, 0) AS total_sales_net_profit,
        COALESCE(ca.catalog_net_loss, 0) AS total_catalog_net_loss,
        COALESCE(wa.web_net_loss, 0) AS total_web_net_loss,
        COALESCE(sa.sales_net_profit, 0) - (COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) AS net_profit_after_returns,
        COALESCE(sa.total_quantity, 0) AS total_quantity_sold,
        ROW_NUMBER() OVER (
            PARTITION BY d.d_year, d.d_month_seq
            ORDER BY COALESCE(sa.sales_net_profit, 0) - (COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) DESC
        ) AS store_rank
    FROM date_dim d
    LEFT JOIN catalog_agg ca ON ca.d_date_sk = d.d_date_sk
    LEFT JOIN web_agg wa ON wa.d_date_sk = d.d_date_sk
    LEFT JOIN sales_agg sa ON sa.d_date_sk = d.d_date_sk
    LEFT JOIN store s
        ON s.s_store_sk = sa.ss_store_sk
        AND s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    d_year,
    d_month_seq,
    s_store_id,
    s_store_name,
    total_sales_tickets,
    total_sales_net_profit,
    total_catalog_net_loss,
    total_web_net_loss,
    net_profit_after_returns,
    total_quantity_sold,
    store_rank
FROM joined_data
WHERE store_rank <= 5
ORDER BY d_year, d_month_seq, store_rank
LIMIT 100
