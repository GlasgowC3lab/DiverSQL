WITH
sales AS (
    SELECT cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           cs_bill_customer_sk AS customer_sk,
           cs_quantity AS quantity,
           cs_net_paid AS net_paid,
           cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_customer_sk,
           ss_quantity,
           ss_net_paid,
           ss_net_profit,
           'store'
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_bill_customer_sk,
           ws_quantity,
           ws_net_paid,
           ws_net_profit,
           'web'
    FROM web_sales
),
returns AS (
    SELECT cr_returned_date_sk AS date_sk,
           cr_item_sk AS item_sk,
           cr_refunded_customer_sk AS customer_sk,
           cr_return_quantity AS quantity,
           cr_refunded_cash AS refunded_cash,
           cr_net_loss AS net_loss,
           'catalog' AS channel
    FROM catalog_returns
    UNION ALL
    SELECT sr_returned_date_sk,
           sr_item_sk,
           sr_customer_sk,
           sr_return_quantity,
           sr_refunded_cash,
           sr_net_loss,
           'store'
    FROM store_returns
    UNION ALL
    SELECT wr_returned_date_sk,
           wr_item_sk,
           wr_refunded_customer_sk,
           wr_return_quantity,
           wr_refunded_cash,
           wr_net_loss,
           'web'
    FROM web_returns
),
sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        s.item_sk,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.net_profit) AS total_net_profit
    FROM sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_moy, s.item_sk
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        r.item_sk,
        SUM(r.refunded_cash) AS total_refunded_cash,
        SUM(r.net_loss) AS total_net_loss
    FROM returns r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_moy, r.item_sk
),
combined AS (
    SELECT
        COALESCE(s.d_year, r.d_year) AS sale_year,
        COALESCE(s.d_moy, r.d_moy) AS sale_month,
        i.i_category,
        i.i_brand,
        COALESCE(s.total_net_paid, 0) AS total_sales_net_paid,
        COALESCE(r.total_refunded_cash, 0) AS total_returns_refunded,
        COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0) AS net_profit
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
        ON s.d_year = r.d_year AND s.d_moy = r.d_moy AND s.item_sk = r.item_sk
    LEFT JOIN item i ON i.i_item_sk = COALESCE(s.item_sk, r.item_sk)
    WHERE COALESCE(s.d_year, r.d_year) BETWEEN 2000 AND 2002
)
SELECT
    sale_year,
    sale_month,
    i_category,
    i_brand,
    total_sales_net_paid,
    total_returns_refunded,
    net_profit,
    LAG(net_profit) OVER (PARTITION BY i_category ORDER BY sale_year, sale_month) AS prior_month_profit,
    net_profit - LAG(net_profit) OVER (PARTITION BY i_category ORDER BY sale_year, sale_month) AS profit_change,
    ROW_NUMBER() OVER (PARTITION BY sale_year, sale_month ORDER BY net_profit DESC) AS profit_rank
FROM combined
ORDER BY sale_year, sale_month, net_profit DESC
LIMIT 100
