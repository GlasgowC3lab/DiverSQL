WITH unified_sales AS (
    SELECT
        'store' AS channel,
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_sold_time_sk AS sold_time_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_store_sk AS location_sk,
        ss.ss_promo_sk AS promo_sk,
        ss.ss_ticket_number AS order_number,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid AS net_paid,
        ss.ss_ext_discount_amt AS discount_amount
    FROM store_sales ss
    UNION ALL
    SELECT
        'catalog' AS channel,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
    UNION ALL
    SELECT
        'web' AS channel,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_page_sk,
        ws.ws_promo_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt
    FROM web_sales ws
),
unified_returns AS (
    SELECT
        'store' AS channel,
        sr.sr_returned_date_sk AS return_date_sk,
        sr.sr_return_time_sk AS return_time_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_customer_sk AS customer_sk,
        sr.sr_store_sk AS location_sk,
        sr.sr_return_quantity AS quantity,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    UNION ALL
    SELECT
        'catalog' AS channel,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_call_center_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
    UNION ALL
    SELECT
        'web' AS channel,
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_web_page_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM web_returns wr
),
sales_with_date AS (
    SELECT
        s.channel,
        d.d_year AS year,
        d.d_month_seq AS month,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_item_id,
        s.item_sk,
        s.customer_sk,
        s.location_sk,
        s.promo_sk,
        s.order_number,
        s.sold_date_sk,
        s.sold_time_sk,
        s.quantity,
        s.sales_amount,
        s.net_profit,
        s.net_paid,
        s.discount_amount
    FROM unified_sales s
    LEFT JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON s.item_sk = i.i_item_sk
),
returns_with_date AS (
    SELECT
        r.channel,
        d.d_year AS year,
        d.d_month_seq AS month,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_item_id,
        r.item_sk,
        r.customer_sk,
        r.location_sk,
        r.return_date_sk,
        r.return_time_sk,
        r.quantity AS return_quantity,
        r.return_amount,
        r.net_loss
    FROM unified_returns r
    LEFT JOIN date_dim d ON r.return_date_sk = d.d_date_sk
    LEFT JOIN item i ON r.item_sk = i.i_item_sk
),
channel_monthly_agg AS (
    SELECT
        agg.channel,
        agg.year,
        agg.month,
        agg.i_category,
        agg.total_sales,
        agg.total_profit,
        agg.total_quantity,
        agg.total_return_amount,
        agg.total_return_loss,
        agg.net_sales,
        agg.net_profit_adj,
        row_number() OVER (PARTITION BY agg.channel, agg.year, agg.month ORDER BY agg.total_sales DESC) AS sales_rank
    FROM (
        SELECT
            s.channel,
            s.year,
            s.month,
            s.i_category,
            sum(s.sales_amount) AS total_sales,
            sum(s.net_profit) AS total_profit,
            sum(s.quantity) AS total_quantity,
            sum(coalesce(r.return_amount, 0)) AS total_return_amount,
            sum(coalesce(r.net_loss, 0)) AS total_return_loss,
            sum(s.sales_amount) - sum(coalesce(r.return_amount, 0)) AS net_sales,
            sum(s.net_profit) - sum(coalesce(r.net_loss, 0)) AS net_profit_adj
        FROM sales_with_date s
        LEFT JOIN returns_with_date r
          ON s.channel = r.channel
         AND s.item_sk = r.item_sk
         AND s.customer_sk = r.customer_sk
         AND s.sold_date_sk = r.return_date_sk
        GROUP BY
            s.channel,
            s.year,
            s.month,
            s.i_category
    ) agg
),
top_items_by_category AS (
    SELECT
        channel,
        year,
        month,
        i_category,
        item_id,
        total_sales,
        total_quantity,
        item_rank
    FROM (
        SELECT
            s.channel,
            s.year,
            s.month,
            s.i_category,
            i.i_item_id AS item_id,
            sum(s.sales_amount) AS total_sales,
            sum(s.quantity) AS total_quantity,
            row_number() OVER (PARTITION BY s.channel, s.year, s.month, s.i_category ORDER BY sum(s.sales_amount) DESC) AS item_rank
        FROM sales_with_date s
        JOIN item i ON s.item_sk = i.i_item_sk
        GROUP BY
            s.channel,
            s.year,
            s.month,
            s.i_category,
            i.i_item_id
    ) sub
    WHERE item_rank <= 5
)
SELECT
    cma.channel,
    cma.year,
    cma.month,
    cma.i_category,
    cma.total_sales,
    cma.total_profit,
    cma.total_quantity,
    cma.total_return_amount,
    cma.total_return_loss,
    cma.net_sales,
    cma.net_profit_adj,
    cma.sales_rank,
    t.item_id AS top_item_id,
    t.total_sales AS top_item_sales,
    t.total_quantity AS top_item_quantity,
    t.item_rank AS top_item_rank
FROM channel_monthly_agg cma
LEFT JOIN top_items_by_category t
  ON cma.channel = t.channel
 AND cma.year = t.year
 AND cma.month = t.month
 AND cma.i_category = t.i_category
ORDER BY cma.channel, cma.year, cma.month, cma.sales_rank
