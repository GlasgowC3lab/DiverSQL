WITH sales_union AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        d.d_year,
        cs.cs_item_sk AS item_sk,
        i.i_category AS item_category,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_ext_discount_amt AS discount_amount,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_call_center_sk AS call_center_sk,
        CAST(NULL AS INTEGER) AS store_sk,
        CAST(NULL AS INTEGER) AS web_page_sk,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    UNION ALL
    SELECT
        ss.ss_customer_sk AS customer_sk,
        d.d_year,
        ss.ss_item_sk AS item_sk,
        i.i_category AS item_category,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_ext_discount_amt AS discount_amount,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_promo_sk AS promo_sk,
        CAST(NULL AS INTEGER) AS call_center_sk,
        ss.ss_store_sk AS store_sk,
        CAST(NULL AS INTEGER) AS web_page_sk,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    UNION ALL
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        d.d_year,
        ws.ws_item_sk AS item_sk,
        i.i_category AS item_category,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_ext_discount_amt AS discount_amount,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_promo_sk AS promo_sk,
        CAST(NULL AS INTEGER) AS call_center_sk,
        CAST(NULL AS INTEGER) AS store_sk,
        ws.ws_web_page_sk AS web_page_sk,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
), returns_union AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        d.d_year,
        cr.cr_item_sk AS item_sk,
        i.i_category AS item_category,
        -cr.cr_return_quantity AS quantity,
        -cr.cr_return_amt_inc_tax AS sales_amount,
        -cr.cr_return_tax AS discount_amount,
        -cr.cr_refunded_cash AS net_paid,
        -cr.cr_net_loss AS net_profit,
        CAST(NULL AS INTEGER) AS promo_sk,
        cr.cr_call_center_sk AS call_center_sk,
        CAST(NULL AS INTEGER) AS store_sk,
        CAST(NULL AS INTEGER) AS web_page_sk,
        'catalog_return' AS channel
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    UNION ALL
    SELECT
        sr.sr_customer_sk AS customer_sk,
        d.d_year,
        sr.sr_item_sk AS item_sk,
        i.i_category AS item_category,
        -sr.sr_return_quantity AS quantity,
        -sr.sr_return_amt_inc_tax AS sales_amount,
        -sr.sr_return_tax AS discount_amount,
        -sr.sr_refunded_cash AS net_paid,
        -sr.sr_net_loss AS net_profit,
        CAST(NULL AS INTEGER) AS promo_sk,
        CAST(NULL AS INTEGER) AS call_center_sk,
        sr.sr_store_sk AS store_sk,
        CAST(NULL AS INTEGER) AS web_page_sk,
        'store_return' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    UNION ALL
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        d.d_year,
        wr.wr_item_sk AS item_sk,
        i.i_category AS item_category,
        -wr.wr_return_quantity AS quantity,
        -wr.wr_return_amt_inc_tax AS sales_amount,
        -wr.wr_return_tax AS discount_amount,
        -wr.wr_refunded_cash AS net_paid,
        -wr.wr_net_loss AS net_profit,
        CAST(NULL AS INTEGER) AS promo_sk,
        CAST(NULL AS INTEGER) AS call_center_sk,
        CAST(NULL AS INTEGER) AS store_sk,
        wr.wr_web_page_sk AS web_page_sk,
        'web_return' AS channel
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
), combined AS (
    SELECT * FROM sales_union
    UNION ALL
    SELECT * FROM returns_union
), customer_agg AS (
    SELECT
        ca.customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.d_year,
        COUNT(DISTINCT ca.item_sk) AS distinct_items,
        SUM(ca.quantity) AS total_quantity,
        SUM(ca.sales_amount) AS total_sales,
        SUM(ca.discount_amount) AS total_discount,
        SUM(ca.net_paid) AS total_net_paid,
        SUM(ca.net_profit) AS total_net_profit,
        COUNT(DISTINCT ca.promo_sk) FILTER (WHERE ca.promo_sk IS NOT NULL) AS distinct_promos,
        COUNT(DISTINCT ca.channel) AS distinct_channels,
        SUM(CASE WHEN ca.channel = 'store' THEN ca.sales_amount ELSE 0 END) AS store_sales,
        SUM(CASE WHEN ca.channel = 'store_return' THEN ca.sales_amount ELSE 0 END) AS store_returns,
        SUM(CASE WHEN ca.channel = 'catalog' THEN ca.sales_amount ELSE 0 END) AS catalog_sales,
        SUM(CASE WHEN ca.channel = 'catalog_return' THEN ca.sales_amount ELSE 0 END) AS catalog_returns,
        SUM(CASE WHEN ca.channel = 'web' THEN ca.sales_amount ELSE 0 END) AS web_sales,
        SUM(CASE WHEN ca.channel = 'web_return' THEN ca.sales_amount ELSE 0 END) AS web_returns
    FROM combined ca
    JOIN customer c ON ca.customer_sk = c.c_customer_sk
    GROUP BY ca.customer_sk, c.c_first_name, c.c_last_name, ca.d_year
), ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM customer_agg
    WHERE total_net_profit > 0
)
SELECT
    profit_rank,
    customer_sk,
    c_first_name,
    c_last_name,
    d_year,
    total_quantity,
    total_sales,
    total_discount,
    total_net_paid,
    total_net_profit,
    distinct_items,
    distinct_promos,
    distinct_channels,
    store_sales,
    store_returns,
    catalog_sales,
    catalog_returns,
    web_sales,
    web_returns
FROM ranked
WHERE profit_rank <= 20
ORDER BY profit_rank
