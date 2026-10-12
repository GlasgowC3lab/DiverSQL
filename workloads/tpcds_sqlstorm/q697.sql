WITH date_filter AS (
    SELECT
        d_date_sk,
        d_date,
        d_year,
        d_month_seq,
        d_week_seq,
        CASE
            WHEN d_holiday = 'Y' THEN 'Holiday'
            WHEN d_weekend = 'Y' THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type
    FROM date_dim
    WHERE d_year = 2001
        OR (d_month_seq BETWEEN 100 AND 200 AND mod(d_week_seq, 2) = 0)
        AND (d_holiday IS NULL OR d_holiday <> 'Y')
        AND (d_weekend = 'Y' OR d_weekend IS NULL)
        AND date_diff('day', DATE '2001-01-01', d_date) BETWEEN 0 AND 365
),
unified_sales AS (
    SELECT
        cs.cs_sold_date_sk AS sales_date_sk,
        cs.cs_bill_customer_sk AS sales_customer_sk,
        cs.cs_bill_addr_sk AS sales_addr_sk,
        'catalog' AS sales_channel,
        cs.cs_net_paid AS net_paid,
        cs.cs_ext_sales_price AS ext_sales,
        cs.cs_quantity AS quantity,
        cs.cs_item_sk AS item_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_order_number AS order_number
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        'store' AS sales_channel,
        ss.ss_net_paid,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_addr_sk,
        'web' AS sales_channel,
        ws.ws_net_paid,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_order_number
    FROM web_sales ws
),
customer_detail AS (
    SELECT
        u.sales_customer_sk,
        COALESCE(c.c_customer_id, 'UNKNOWN') AS customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_current_cdemo_sk,
        c.c_current_hdemo_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_gmt_offset,
        u.sales_channel,
        u.sales_date_sk,
        d.d_date,
        u.net_paid,
        u.ext_sales,
        u.quantity,
        u.item_sk,
        i.i_item_id,
        i.i_product_name,
        p.p_promo_name,
        ROW_NUMBER() OVER (PARTITION BY u.sales_customer_sk ORDER BY u.sales_date_sk DESC NULLS LAST) AS rn_recent_sale,
        CASE
            WHEN u.sales_channel = 'catalog' THEN COALESCE(u.promo_sk, -1)
            WHEN u.sales_channel = 'store'   THEN COALESCE(u.promo_sk, -2)
            ELSE COALESCE(u.promo_sk, -3)
        END AS promo_sk_resolved
    FROM unified_sales u
    LEFT JOIN date_filter d ON u.sales_date_sk = d.d_date_sk
    LEFT JOIN customer c ON u.sales_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON u.sales_addr_sk = ca.ca_address_sk
    LEFT JOIN item i ON u.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON u.promo_sk = p.p_promo_sk
    WHERE (d.day_type = 'Weekend' OR d.day_type = 'Weekday')
      AND (ca.ca_state = 'CA' OR ca.ca_state IS NULL)
),
aggregated_sales AS (
    SELECT
        cd.sales_customer_sk,
        cd.customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.sales_channel,
        cd.c_current_cdemo_sk,
        COUNT(*) AS total_transactions,
        SUM(cd.net_paid) AS total_net_paid,
        SUM(cd.ext_sales) AS total_ext_sales,
        AVG(cd.net_paid) AS avg_net_paid,
        MAX(cd.net_paid) AS max_net_paid,
        MIN(cd.net_paid) AS min_net_paid,
        COUNT(DISTINCT cd.item_sk) AS distinct_items,
        array_join(array_agg(DISTINCT cd.sales_channel), ',') AS channels,
        array_join(array_agg(CONCAT(cd.sales_channel, ':', CAST(cd.promo_sk_resolved AS VARCHAR))), ',') AS channel_promo_map
    FROM customer_detail cd
    GROUP BY
        cd.sales_customer_sk,
        cd.customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.sales_channel,
        cd.c_current_cdemo_sk
) SELECT * FROM aggregated_sales
