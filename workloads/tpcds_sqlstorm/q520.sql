WITH sales_union AS (
    SELECT
        d.d_date AS sold_date,
        'catalog' AS channel,
        cc.cc_city AS city,
        i.i_category AS category,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_profit AS profit,
        cs.cs_ext_discount_amt AS discount_amount,
        cs.cs_order_number AS order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2000

    UNION ALL

    SELECT
        d.d_date AS sold_date,
        'store' AS channel,
        s.s_city AS city,
        i.i_category AS category,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS profit,
        ss.ss_ext_discount_amt AS discount_amount,
        ss.ss_ticket_number AS order_number
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2000

    UNION ALL

    SELECT
        d.d_date AS sold_date,
        'web' AS channel,
        we.web_city AS city,
        i.i_category AS category,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS profit,
        ws.ws_ext_discount_amt AS discount_amount,
        ws.ws_order_number AS order_number
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2000
),
agg AS (
    SELECT
        channel,
        sold_date,
        city,
        category,
        SUM(sales_amount) AS total_sales,
        SUM(profit) AS total_profit,
        SUM(quantity) AS total_quantity,
        AVG(discount_amount) AS avg_discount,
        COUNT(DISTINCT order_number) AS distinct_orders
    FROM sales_union
    GROUP BY ROLLUP (channel, sold_date, city, category)
),
final AS (
    SELECT
        channel,
        sold_date,
        city,
        category,
        total_sales,
        total_profit,
        total_quantity,
        avg_discount,
        distinct_orders,
        SUM(total_sales) OVER (PARTITION BY channel ORDER BY sold_date
                               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
        ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS sales_rank
    FROM agg
    WHERE total_sales IS NOT NULL
)
SELECT *
FROM final
ORDER BY channel, sold_date, city, category
LIMIT 200
