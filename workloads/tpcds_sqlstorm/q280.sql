WITH
sales_union AS (
    SELECT cs_sold_date_sk AS sales_date_sk,
           cs_bill_customer_sk AS sales_customer_sk,
           cs_item_sk AS sales_item_sk,
           cs_quantity AS sales_quantity,
           cs_net_profit AS sales_net_profit,
           'catalog' AS sales_source,
           (SELECT i_category FROM item i WHERE i.i_item_sk = cs_item_sk) AS item_category
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_customer_sk,
           ss_item_sk,
           ss_quantity,
           ss_net_profit,
           'store',
           (SELECT i_category FROM item i WHERE i.i_item_sk = ss_item_sk)
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_bill_customer_sk,
           ws_item_sk,
           ws_quantity,
           ws_net_profit,
           'web',
           (SELECT i_category FROM item i WHERE i.i_item_sk = ws_item_sk)
    FROM web_sales
),
returns_union AS (
    SELECT cr_returned_date_sk AS return_date_sk,
           cr_returning_customer_sk AS return_customer_sk,
           cr_item_sk AS return_item_sk,
           cr_return_quantity AS return_quantity,
           cr_net_loss AS return_net_loss,
           'catalog' AS return_source
    FROM catalog_returns
    UNION ALL
    SELECT sr_returned_date_sk,
           sr_customer_sk,
           sr_item_sk,
           sr_return_quantity,
           sr_net_loss,
           'store'
    FROM store_returns
    UNION ALL
    SELECT wr_returned_date_sk,
           wr_returning_customer_sk,
           wr_item_sk,
           wr_return_quantity,
           wr_net_loss,
           'web'
    FROM web_returns
),
sales_agg AS (
    SELECT su.sales_date_sk,
           su.sales_customer_sk,
           su.sales_item_sk,
           su.item_category,
           SUM(su.sales_quantity) AS total_quantity_sold,
           SUM(su.sales_net_profit) AS total_net_profit
    FROM sales_union su
    GROUP BY su.sales_date_sk, su.sales_customer_sk, su.sales_item_sk, su.item_category
),
returns_agg AS (
    SELECT ru.return_date_sk,
           ru.return_customer_sk,
           ru.return_item_sk,
           SUM(ru.return_quantity) AS total_quantity_returned,
           SUM(ru.return_net_loss) AS total_net_loss
    FROM returns_union ru
    GROUP BY ru.return_date_sk, ru.return_customer_sk, ru.return_item_sk
),
customer_sales AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           d.d_year,
           SUM(sa.total_net_profit) AS year_net_profit,
           SUM(sa.total_quantity_sold) AS year_quantity_sold,
           SUM(COALESCE(ra.total_net_loss, 0)) AS year_net_loss,
           SUM(COALESCE(ra.total_quantity_returned, 0)) AS year_quantity_returned
    FROM customer c
    LEFT JOIN sales_agg sa
      ON c.c_customer_sk = sa.sales_customer_sk
    LEFT JOIN returns_agg ra
      ON c.c_customer_sk = ra.return_customer_sk
         AND sa.sales_date_sk = ra.return_date_sk
         AND sa.sales_item_sk = ra.return_item_sk
    LEFT JOIN date_dim d
      ON sa.sales_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, d.d_year
),
customer_rank AS (
    SELECT cs.c_customer_sk,
           cs.c_customer_id,
           cs.d_year,
           cs.year_net_profit,
           cs.year_net_loss,
           cs.year_quantity_sold,
           cs.year_quantity_returned,
           (cs.year_net_profit - cs.year_net_loss) AS net_profit_adj,
           CASE WHEN cs.year_quantity_sold = 0 THEN NULL
                ELSE (cs.year_net_profit - cs.year_net_loss) / cs.year_quantity_sold END AS profit_per_item,
           CONCAT('Cust-', cs.c_customer_id) AS cust_label,
           RANK() OVER (PARTITION BY cs.d_year ORDER BY (cs.year_net_profit - cs.year_net_loss) DESC) AS profit_rank,
           (SELECT COALESCE(prev.year_net_profit,0)
            FROM customer_sales prev
            WHERE prev.c_customer_sk = cs.c_customer_sk
              AND prev.d_year = cs.d_year - 1) AS prev_year_net_profit,
           CASE WHEN (cs.year_net_profit - cs.year_net_loss) >
                 (SELECT COALESCE(prev.year_net_profit,0) - COALESCE(prev.year_net_loss,0)
                  FROM customer_sales prev
                  WHERE prev.c_customer_sk = cs.c_customer_sk
                    AND prev.d_year = cs.d_year - 1) THEN 1 ELSE 0 END AS profit_growth_flag,
           SUM(cs.year_net_profit - cs.year_net_loss) OVER (PARTITION BY cs.d_year) AS total_year_adj_profit
    FROM customer_sales cs
    WHERE cs.year_net_profit IS NOT NULL
      AND (cs.year_quantity_sold > 0 OR cs.year_quantity_returned > 0)
)
SELECT *
FROM customer_rank
WHERE profit_rank <= 10
ORDER BY d_year, profit_rank
