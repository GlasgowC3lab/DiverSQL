WITH
sales_union AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_net_profit AS profit,
           ss_quantity AS qty,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_net_profit,
           ws_quantity,
           'web'
    FROM web_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_net_profit,
           cs_quantity,
           'catalog'
    FROM catalog_sales
),
returns_union AS (
    SELECT sr_returned_date_sk AS date_sk,
           sr_item_sk AS item_sk,
           -sr_net_loss AS profit_adj,
           sr_return_quantity AS qty,
           'store' AS channel
    FROM store_returns
    UNION ALL
    SELECT wr_returned_date_sk,
           wr_item_sk,
           -wr_net_loss,
           wr_return_quantity,
           'web'
    FROM web_returns
    UNION ALL
    SELECT cr_returned_date_sk,
           cr_item_sk,
           -cr_net_loss,
           cr_return_quantity,
           'catalog'
    FROM catalog_returns
),
sales_agg AS (
    SELECT date_sk,
           item_sk,
           channel,
           sum(profit) AS total_sales_profit,
           sum(qty) AS total_sales_qty
    FROM sales_union
    GROUP BY date_sk, item_sk, channel
),
returns_agg AS (
    SELECT date_sk,
           item_sk,
           channel,
           sum(profit_adj) AS total_return_adj,
           sum(qty) AS total_return_qty
    FROM returns_union
    GROUP BY date_sk, item_sk, channel
),
combined AS (
    SELECT COALESCE(s.date_sk, r.date_sk) AS date_sk,
           COALESCE(s.item_sk, r.item_sk) AS item_sk,
           COALESCE(s.channel, r.channel) AS channel,
           COALESCE(s.total_sales_profit, 0) AS total_sales_profit,
           COALESCE(s.total_sales_qty, 0) AS total_sales_qty,
           COALESCE(r.total_return_adj, 0) AS total_return_adj,
           COALESCE(r.total_return_qty, 0) AS total_return_qty
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
        ON s.date_sk = r.date_sk
       AND s.item_sk = r.item_sk
       AND s.channel = r.channel
),
daily_item_summary AS (
    SELECT c.date_sk,
           d.d_date,
           c.item_sk,
           i.i_product_name,
           i.i_category,
           i.i_brand,
           c.channel,
           c.total_sales_profit,
           c.total_sales_qty,
           c.total_return_adj,
           c.total_return_qty,
           (c.total_sales_profit + c.total_return_adj) AS net_profit,
           (c.total_sales_qty - c.total_return_qty) AS net_qty,
           CASE
               WHEN c.total_sales_qty = 0 THEN NULL
               ELSE (c.total_sales_profit + c.total_return_adj) / c.total_sales_qty
           END AS profit_per_unit
    FROM combined c
    JOIN date_dim d ON c.date_sk = d.d_date_sk
    JOIN item i ON c.item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
item_rank_by_date AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY net_profit DESC) AS profit_rank,
           RANK() OVER (PARTITION BY d_date ORDER BY net_profit DESC) AS profit_dense_rank,
           SUM(net_profit) OVER (PARTITION BY d_date) AS total_net_profit_date,
           SUM(net_qty) OVER (PARTITION BY d_date) AS total_net_qty_date
    FROM daily_item_summary
),
eligible_keys AS (
    SELECT date_sk,
           item_sk,
           channel
    FROM item_rank_by_date
    WHERE net_profit > 0
    EXCEPT
    SELECT date_sk,
           item_sk,
           channel
    FROM item_rank_by_date
    WHERE net_qty = 0
),
customer_ltv AS (
    SELECT cust.c_customer_sk,
           cust.c_customer_id,
           (SELECT SUM(ss_net_paid_inc_tax) FROM store_sales ss WHERE ss.ss_customer_sk = cust.c_customer_sk) AS store_spent,
           (SELECT SUM(ws_net_paid_inc_tax) FROM web_sales ws WHERE ws.ws_bill_customer_sk = cust.c_customer_sk) AS web_spent,
           (SELECT SUM(cs_net_paid_inc_tax) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = cust.c_customer_sk) AS catalog_spent,
           (SELECT SUM(sr_net_loss) FROM store_returns sr WHERE sr.sr_customer_sk = cust.c_customer_sk) AS store_loss,
           (SELECT SUM(wr_net_loss) FROM web_returns wr WHERE wr.wr_refunded_customer_sk = cust.c_customer_sk) AS web_loss,
           (SELECT SUM(cr_net_loss) FROM catalog_returns cr WHERE cr.cr_returning_customer_sk = cust.c_customer_sk) AS catalog_loss
    FROM customer cust
),
customer_ltv_agg AS (
    SELECT c_ltv.c_customer_sk,
           c_ltv.c_customer_id,
           COALESCE(store_spent, 0) + COALESCE(web_spent, 0) + COALESCE(catalog_spent, 0) AS total_spent,
           COALESCE(store_loss, 0) + COALESCE(web_loss, 0) + COALESCE(catalog_loss, 0) AS total_loss,
           CASE
               WHEN (COALESCE(store_spent, 0) + COALESCE(web_spent, 0) + COALESCE(catalog_spent, 0)) > 0
               THEN (COALESCE(store_spent, 0) + COALESCE(web_spent, 0) + COALESCE(catalog_spent, 0) -
                     (COALESCE(store_loss, 0) + COALESCE(web_loss, 0) + COALESCE(catalog_loss, 0))) /
                    (COALESCE(store_spent, 0) + COALESCE(web_spent, 0) + COALESCE(catalog_spent, 0))
               ELSE NULL
           END AS net_margin_ratio
    FROM customer_ltv c_ltv
),
top_customer AS (
    SELECT *
    FROM customer_ltv_agg
    ORDER BY total_spent DESC
    LIMIT 1
),
final AS (
    SELECT ir.d_date,
           ir.i_product_name,
           ir.i_category,
           ir.i_brand,
           ir.channel,
           ir.total_sales_qty,
           ir.total_return_qty,
           ir.total_sales_profit,
           ir.total_return_adj,
           ir.net_profit,
           ir.net_qty,
           ir.profit_per_unit,
           ir.profit_rank,
           ir.total_net_profit_date,
           ir.total_net_qty_date,
           CONCAT('Rank ', CAST(ir.profit_rank AS VARCHAR), ' on ', CAST(ir.d_date AS VARCHAR)) AS rank_label,
           tl.c_customer_id AS top_customer_id,
           tl.total_spent AS top_customer_total_spent,
           tl.total_loss AS top_customer_total_loss,
           tl.net_margin_ratio AS top_customer_margin
    FROM item_rank_by_date ir
    JOIN eligible_keys ek
      ON ir.date_sk = ek.date_sk
     AND ir.item_sk = ek.item_sk
     AND ir.channel = ek.channel
    CROSS JOIN top_customer tl
    WHERE ir.profit_rank <= 5
      AND (ir.i_category LIKE '%Elect%' OR ir.i_brand IS NOT NULL)
)
SELECT *
FROM final
ORDER BY d_date, profit_rank
