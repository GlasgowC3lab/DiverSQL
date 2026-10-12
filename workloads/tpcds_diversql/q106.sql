WITH sampled_store AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),

base AS (
    SELECT
        d_sold.d_year,
        cd.cd_gender,
        cs.cs_ext_sales_price,
        ss.ss_net_paid,
        ws.ws_net_paid,
        cr.cr_net_loss
    FROM sampled_store ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_returned_date_sk = d_sold.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN date_dim d_open
        ON wsite.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close
        ON wsite.web_close_date_sk = d_close.d_date_sk
    WHERE d_sold.d_year = 2001
      AND cd.cd_gender = 'M'
      AND cs.cs_ext_list_price > 2000
      AND ws.ws_quantity >= 2
      AND cs.cs_ext_ship_cost < 500
),

agg AS (
    SELECT
        d_year,
        cd_gender,
        SUM(cs_ext_sales_price) AS total_sales_price,
        SUM(ss_net_paid) AS total_store_net_paid,
        SUM(ws_net_paid) AS total_web_net_paid,
        SUM(cr_net_loss) AS total_return_loss,
        COUNT(*) AS txn_count
    FROM base
    GROUP BY GROUPING SETS ((d_year, cd_gender), (d_year))
)

SELECT
    d_year,
    cd_gender,
    total_sales_price,
    total_store_net_paid,
    total_web_net_paid,
    total_return_loss,
    txn_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales_price DESC) AS sales_rank
FROM agg
ORDER BY d_year, sales_rank
LIMIT 100
