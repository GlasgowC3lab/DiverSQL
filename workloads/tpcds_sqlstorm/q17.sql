WITH
sales_union AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_order_number AS order_number,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS profit,
        cs.cs_net_paid AS net_paid,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_catalog_page_sk AS catalog_page_sk,
        NULL AS web_page_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        'catalog' AS channel,
        cs.cs_sold_time_sk AS time_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0

    UNION ALL

    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_ticket_number AS order_number,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS profit,
        ss.ss_net_paid AS net_paid,
        NULL AS call_center_sk,
        NULL AS catalog_page_sk,
        NULL AS web_page_sk,
        ss.ss_customer_sk AS customer_sk,
        'store' AS channel,
        ss.ss_sold_time_sk AS time_sk
    FROM store_sales ss
    WHERE ss.ss_quantity > 0

    UNION ALL

    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_order_number AS order_number,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS profit,
        ws.ws_net_paid AS net_paid,
        NULL AS call_center_sk,
        NULL AS catalog_page_sk,
        ws.ws_web_page_sk AS web_page_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        'web' AS channel,
        ws.ws_sold_time_sk AS time_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
),
returns_union AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_order_number AS order_number,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_net_loss AS net_loss,
        'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_ticket_number AS order_number,
        sr.sr_return_quantity AS return_quantity,
        sr.sr_net_loss AS net_loss,
        'store' AS channel
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_order_number AS order_number,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_net_loss AS net_loss,
        'web' AS channel
    FROM web_returns wr
),
daily_agg_base AS (
    SELECT
        d.d_date,
        s.channel,
        SUM(s.profit) AS total_profit,
        SUM(s.net_paid) AS total_net_paid,
        COUNT(DISTINCT s.order_number) AS orders,
        SUM(CASE WHEN s.call_center_sk IS NOT NULL THEN 1 ELSE 0 END) AS call_center_sales,
        SUM(CASE WHEN s.catalog_page_sk IS NOT NULL THEN 1 ELSE 0 END) AS catalog_page_sales,
        SUM(CASE WHEN s.web_page_sk IS NOT NULL THEN 1 ELSE 0 END) AS web_page_sales
    FROM sales_union s
    LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
    GROUP BY d.d_date, s.channel
),
daily_agg AS (
    SELECT
        d_date,
        channel,
        total_profit,
        total_net_paid,
        orders,
        call_center_sales,
        catalog_page_sales,
        web_page_sales,
        SUM(total_profit) OVER (PARTITION BY channel ORDER BY d_date) AS cum_profit,
        PERCENT_RANK() OVER (PARTITION BY channel ORDER BY total_profit DESC) AS profit_rank
    FROM daily_agg_base
),
top_customers_base AS (
    SELECT
        c.c_customer_id,
        CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS cust_name,
        COALESCE(c.c_email_address, 'unknown@unknown.com') AS email,
        s.channel,
        SUM(s.profit) AS cust_profit
    FROM sales_union s
    LEFT JOIN customer c ON s.customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, c.c_email_address, s.channel
    HAVING SUM(s.profit) > (SELECT AVG(total_profit) FROM daily_agg)
),
top_customers AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY channel ORDER BY cust_profit DESC) AS rn
    FROM top_customers_base
),
missing_returns AS (
    SELECT
        d.d_date AS d_date,
        s.channel,
        s.order_number,
        s.item_sk,
        s.profit,
        s.net_paid,
        COALESCE(r.net_loss, 0) AS net_loss,
        CASE WHEN r.order_number IS NULL THEN TRUE ELSE FALSE END AS return_missing
    FROM sales_union s
    LEFT JOIN returns_union r
      ON s.order_number = r.order_number AND s.channel = r.channel
    LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
    WHERE r.order_number IS NULL
),
final_result AS (
    SELECT
        da.d_date,
        da.channel,
        da.total_profit,
        da.total_net_paid,
        da.orders,
        da.cum_profit,
        da.profit_rank,
        CASE
            WHEN da.total_profit > 1000000 THEN 'Very High'
            WHEN da.total_profit > 100000 THEN 'High'
            WHEN da.total_profit > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        tc.cust_name,
        tc.cust_profit,
        mr.return_missing
    FROM daily_agg da
    LEFT JOIN top_customers tc
      ON da.channel = tc.channel
    LEFT JOIN missing_returns mr
      ON da.d_date = mr.d_date AND da.channel = mr.channel
    WHERE da.total_profit > 0
      AND (tc.rn <= 5 OR tc.rn IS NULL)
)
SELECT *
FROM final_result
WHERE (cust_name IS NOT NULL AND cust_profit > 0) OR return_missing = TRUE
ORDER BY d_date DESC, channel, profit_rank
