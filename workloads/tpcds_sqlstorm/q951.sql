WITH
date_month AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq
    FROM date_dim
    WHERE d_year BETWEEN 2001 AND 2002
),
item_dim AS (
    SELECT i_item_sk,
           i_category
    FROM item
),
unified_sales AS (
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_item_sk AS item_sk,
        ss_customer_sk AS customer_sk,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit,
        ss_ext_discount_amt AS discount_amt,
        ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        cs_bill_customer_sk,
        cs_net_paid,
        cs_net_profit,
        cs_ext_discount_amt,
        cs_quantity
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_bill_customer_sk,
        ws_net_paid,
        ws_net_profit,
        ws_ext_discount_amt,
        ws_quantity
    FROM web_sales
),
sales_enriched AS (
    SELECT
        i.i_category,
        dm.d_year,
        dm.d_month_seq AS month_seq,
        s.customer_sk,
        s.net_paid,
        s.net_profit,
        s.discount_amt,
        s.quantity
    FROM unified_sales s
    JOIN item_dim i ON s.item_sk = i.i_item_sk
    JOIN date_month dm ON s.sold_date_sk = dm.d_date_sk
),
unified_returns AS (
    SELECT
        cr_returned_date_sk AS returned_date_sk,
        cr_item_sk AS item_sk,
        cr_net_loss AS net_loss,
        cr_return_quantity AS quantity
    FROM catalog_returns
    UNION ALL
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        sr_net_loss,
        sr_return_quantity
    FROM store_returns
    UNION ALL
    SELECT
        wr_returned_date_sk,
        wr_item_sk,
        wr_net_loss,
        wr_return_quantity
    FROM web_returns
),
returns_enriched AS (
    SELECT
        i.i_category,
        dm.d_year,
        dm.d_month_seq AS month_seq,
        r.net_loss,
        r.quantity AS return_quantity
    FROM unified_returns r
    JOIN item_dim i ON r.item_sk = i.i_item_sk
    JOIN date_month dm ON r.returned_date_sk = dm.d_date_sk
),
sales_agg AS (
    SELECT
        i_category,
        d_year,
        month_seq,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(discount_amt) AS total_discount,
        SUM(quantity) AS total_quantity
    FROM sales_enriched
    GROUP BY i_category, d_year, month_seq
),
returns_agg AS (
    SELECT
        i_category,
        d_year,
        month_seq,
        SUM(net_loss) AS total_net_loss,
        SUM(return_quantity) AS total_return_quantity
    FROM returns_enriched
    GROUP BY i_category, d_year, month_seq
),
customer_sales AS (
    SELECT
        se.i_category,
        se.d_year,
        se.month_seq,
        se.customer_sk,
        SUM(se.net_paid) AS cust_total_paid,
        SUM(se.quantity) AS cust_total_qty
    FROM sales_enriched se
    GROUP BY se.i_category, se.d_year, se.month_seq, se.customer_sk
),
ranked_customers AS (
    SELECT
        cs.i_category,
        cs.d_year,
        cs.month_seq,
        cs.customer_sk,
        cs.cust_total_paid,
        cs.cust_total_qty,
        ROW_NUMBER() OVER (PARTITION BY cs.i_category, cs.d_year, cs.month_seq ORDER BY cs.cust_total_paid DESC) AS rn
    FROM customer_sales cs
),
top_customers AS (
    SELECT
        rc.i_category,
        rc.d_year,
        rc.month_seq,
        ARRAY_AGG(CAST(rc.customer_sk AS VARCHAR) ORDER BY rc.cust_total_paid DESC) AS top_customer_ids
    FROM ranked_customers rc
    WHERE rc.rn <= 5
    GROUP BY rc.i_category, rc.d_year, rc.month_seq
)
SELECT
    sa.i_category AS category,
    sa.d_year AS year,
    sa.month_seq AS month,
    sa.total_net_paid,
    sa.total_net_profit,
    COALESCE(ra.total_net_loss, 0) AS total_net_loss,
    (sa.total_net_profit - COALESCE(ra.total_net_loss, 0)) AS net_profit_after_returns,
    sa.total_quantity,
    sa.total_discount,
    CASE WHEN sa.total_quantity = 0 THEN 0 ELSE sa.total_discount / sa.total_quantity END AS avg_discount_per_item,
    tc.top_customer_ids
FROM sales_agg sa
LEFT JOIN returns_agg ra ON sa.i_category = ra.i_category AND sa.d_year = ra.d_year AND sa.month_seq = ra.month_seq
LEFT JOIN top_customers tc ON sa.i_category = tc.i_category AND sa.d_year = tc.d_year AND sa.month_seq = tc.month_seq
ORDER BY category, year, month
