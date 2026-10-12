WITH
sales_all AS (
    SELECT
        cs.cs_sold_date_sk AS sale_date_sk,
        cs.cs_sold_time_sk AS sale_time_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_call_center_sk AS call_center_sk,
        NULL AS store_sk,
        NULL AS web_page_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_promo_sk AS promo_sk,
        'catalog' AS channel,
        cs.cs_order_number AS order_number
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        NULL,
        ss.ss_store_sk,
        NULL,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_promo_sk,
        'store' AS channel,
        ss.ss_ticket_number
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        NULL,
        NULL,
        ws.ws_web_page_sk,
        ws.ws_bill_customer_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_promo_sk,
        'web' AS channel,
        ws.ws_order_number
    FROM web_sales ws
),
returns_all AS (
    SELECT
        cr.cr_returned_date_sk AS return_date_sk,
        cr.cr_returned_time_sk AS return_time_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_return_quantity AS quantity,
        cr.cr_return_amt_inc_tax AS return_amount,
        cr.cr_net_loss AS net_loss,
        cr.cr_reason_sk AS reason_sk,
        'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt_inc_tax,
        sr.sr_net_loss,
        sr.sr_reason_sk,
        'store' AS channel
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss,
        wr.wr_reason_sk,
        'web' AS channel
    FROM web_returns wr
),
customer_sales AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS customer_name,
        COALESCE(c.c_preferred_cust_flag, 'UNKNOWN') AS preferred_flag,
        s.channel,
        s.sale_date_sk,
        d.d_date,
        d.d_year,
        s.item_sk,
        i.i_product_name,
        s.quantity,
        s.net_paid,
        s.net_profit,
        SUM(s.net_paid) OVER (PARTITION BY s.customer_sk, s.channel ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS rolling_net_paid,
        ROW_NUMBER() OVER (PARTITION BY s.customer_sk ORDER BY s.net_paid DESC) AS sales_rank,
        (SELECT AVG(s2.net_paid) FROM sales_all s2 WHERE s2.item_sk = s.item_sk) AS avg_item_net_paid,
        COALESCE((SELECT SUM(r.return_amount) FROM returns_all r WHERE r.item_sk = s.item_sk AND r.customer_sk = s.customer_sk), 0) AS total_return_amount,
        CASE
            WHEN s.quantity >= 10 THEN 'BULK'
            WHEN s.quantity >= 5 THEN 'MEDIUM'
            ELSE 'SMALL'
        END AS quantity_class,
        CASE
            WHEN (s.net_paid - s.net_profit) > 0 AND d.d_year = 2001 THEN 1
            WHEN (s.net_paid - s.net_profit) = 0 AND d.d_year = 2002 THEN 2
            ELSE 0
        END AS profit_indicator,
        CONCAT(UPPER(i.i_product_name), ' (', CAST(length(i.i_product_name) AS varchar), ')') AS product_label,
        CASE WHEN s.promo_sk IS NULL THEN 'NO_PROMO' ELSE 'HAS_PROMO' END AS promo_flag
    FROM sales_all s
    LEFT JOIN customer c ON c.c_customer_sk = s.customer_sk
    LEFT JOIN date_dim d ON d.d_date_sk = s.sale_date_sk
    LEFT JOIN item i ON i.i_item_sk = s.item_sk
    WHERE
        d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2003-01-01'
        AND (
            s.channel = 'store' OR
            (s.channel = 'web' AND s.net_paid > 0) OR
            (s.channel = 'catalog' AND s.quantity > 0)
        )
        AND (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
)
SELECT
    customer_sk,
    customer_name,
    preferred_flag,
    channel,
    d_date,
    d_year,
    item_sk,
    i_product_name,
    quantity,
    net_paid,
    net_profit,
    rolling_net_paid,
    sales_rank,
    avg_item_net_paid,
    total_return_amount,
    quantity_class,
    profit_indicator,
    product_label,
    promo_flag
FROM customer_sales
WHERE sales_rank <= 5
ORDER BY customer_sk, channel, sales_rank
