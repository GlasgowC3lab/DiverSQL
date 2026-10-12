WITH
sales_unified AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_store_sk AS channel_id,
        'store' AS channel,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS profit,
        ss.ss_ext_discount_amt AS discount,
        ss.ss_ticket_number AS ticket_number,
        ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_call_center_sk AS channel_id,
        'catalog' AS channel,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_profit AS profit,
        cs.cs_ext_discount_amt AS discount,
        cs.cs_order_number AS ticket_number,
        cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_web_page_sk AS channel_id,
        'web' AS channel,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS profit,
        ws.ws_ext_discount_amt AS discount,
        ws.ws_order_number AS ticket_number,
        ws.ws_promo_sk AS promo_sk
    FROM web_sales ws
),
customer_sales AS (
    SELECT
        s.customer_sk,
        CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
        COUNT(DISTINCT s.item_sk) AS distinct_items,
        SUM(s.sales_amount) AS total_sales,
        SUM(s.profit) AS total_profit,
        MAX(d.d_date) AS most_recent_purchase,
        AVG(CASE WHEN s.quantity > 0 THEN s.discount / s.quantity END) AS avg_discount_per_item,
        MAX(CASE WHEN s.channel = 'store' THEN s.channel_id END) AS last_store_id,
        MAX(CASE WHEN s.channel = 'web' THEN s.channel_id END) AS last_web_page_id,
        MAX(CASE WHEN s.channel = 'catalog' THEN s.channel_id END) AS last_call_center_id
    FROM sales_unified s
    LEFT JOIN customer c ON s.customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
    GROUP BY s.customer_sk, c.c_first_name, c.c_last_name
),
customer_returns AS (
    SELECT
        cs.customer_sk,
        COALESCE((
            SELECT COUNT(*)
            FROM store_returns sr
            WHERE sr.sr_customer_sk = cs.customer_sk
              AND sr.sr_returned_date_sk IS NOT NULL), 0) AS store_return_count,
        COALESCE((
            SELECT COUNT(*)
            FROM catalog_returns cr
            WHERE cr.cr_returning_customer_sk = cs.customer_sk
              AND cr.cr_returned_date_sk IS NOT NULL), 0) AS catalog_return_count,
        COALESCE((
            SELECT COUNT(*)
            FROM web_returns wr
            WHERE wr.wr_refunded_customer_sk = cs.customer_sk
              AND wr.wr_returned_date_sk IS NOT NULL), 0) AS web_return_count
    FROM customer_sales cs
),
customer_prev_year AS (
    SELECT
        cs.customer_sk,
        (SELECT SUM(s.profit)
         FROM sales_unified s
         LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
         WHERE s.customer_sk = cs.customer_sk
           AND d.d_year = year(DATE '2001-01-01') - 1) AS prev_year_profit
    FROM customer_sales cs
),
customer_segments AS (
    SELECT
        cs.customer_sk,
        CASE
            WHEN cs.total_sales > 200000 THEN 'Platinum'
            WHEN cs.total_sales > 100000 THEN 'Gold'
            WHEN cs.total_sales > 50000 THEN 'Silver'
            ELSE 'Bronze'
        END AS segment
    FROM customer_sales cs
),
final AS (
    SELECT
        cs.customer_sk,
        cs.full_name,
        cs.total_sales,
        cs.total_profit,
        cs.most_recent_purchase,
        cs.distinct_items,
        cs.avg_discount_per_item,
        cr.store_return_count,
        cr.catalog_return_count,
        cr.web_return_count,
        cp.prev_year_profit,
        CASE
            WHEN cr.store_return_count + cr.catalog_return_count + cr.web_return_count > 0 THEN 'YES'
            ELSE 'NO'
        END AS has_returned,
        seg.segment,
        CONCAT('Segment: ', seg.segment) AS segment_label,
        ROW_NUMBER() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM customer_sales cs
    LEFT JOIN customer_returns cr ON cs.customer_sk = cr.customer_sk
    LEFT JOIN customer_prev_year cp ON cs.customer_sk = cp.customer_sk
    LEFT JOIN customer_segments seg ON cs.customer_sk = seg.customer_sk
    WHERE cs.total_profit IS NOT NULL
      AND (cs.full_name IS NOT NULL AND cs.full_name <> '')
)
SELECT
    f.customer_sk,
    f.full_name,
    f.total_sales,
    f.total_profit,
    f.most_recent_purchase,
    f.distinct_items,
    COALESCE(ROUND(f.avg_discount_per_item, 2), 0) AS avg_discount_per_item,
    f.store_return_count,
    f.catalog_return_count,
    f.web_return_count,
    f.prev_year_profit,
    f.has_returned,
    f.segment,
    f.segment_label,
    f.profit_rank,
    ROUND(f.total_profit / SUM(f.total_profit) OVER (), 4) AS profit_share
FROM final f
WHERE f.profit_rank <= 10
  AND (f.most_recent_purchase >= DATE '2001-01-01' OR f.most_recent_purchase IS NULL)
ORDER BY f.profit_rank
