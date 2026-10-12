WITH sales_agg AS (
    SELECT
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        d_sold.d_year AS sale_year,
        d_sold.d_moy AS sale_month,
        SUM(cs.cs_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_returns,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_returns,
        SUM(cs.cs_sales_price) - SUM(COALESCE(sr.sr_net_loss, 0)) - SUM(COALESCE(wr.wr_net_loss, 0)) AS net_sales
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_year = 2022
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_name,
        s.s_city,
        d_sold.d_year,
        d_sold.d_moy
)
SELECT
    store_name,
    store_city,
    sale_year,
    sale_month,
    total_sales,
    total_quantity,
    total_discount,
    total_store_returns,
    total_web_returns,
    net_sales,
    row_number() OVER (ORDER BY net_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY net_sales DESC
LIMIT 100
