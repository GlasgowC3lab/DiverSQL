WITH filtered_sales AS (
    SELECT cs.*
    FROM tpcds.catalog_sales cs
    WHERE NOT EXISTS (
        SELECT 1
        FROM tpcds.catalog_returns cr
        WHERE cr.cr_order_number = cs.cs_order_number
    )
),
base AS (
    SELECT
        cc.cc_name,
        i.i_brand,
        i.i_category,
        sm.sm_type,
        wsite.web_name,
        SUM(cs.cs_net_paid)                               AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number)                AS order_cnt,
        AVG(cs.cs_quantity)                               AS avg_quantity,
        SUM(COALESCE(wr.wr_return_quantity, 0))           AS total_return_qty
    FROM filtered_sales cs
    JOIN tpcds.call_center cc        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm          ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN tpcds.item i                ON cs.cs_item_sk        = i.i_item_sk
    JOIN tpcds.promotion p          ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN tpcds.customer c           ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address ca  ON cs.cs_bill_addr_sk   = ca.ca_address_sk
    LEFT JOIN tpcds.web_sales ws    ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN tpcds.web_site wsite  ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN tpcds.web_returns wr  ON wr.wr_order_number = ws.ws_order_number
    WHERE
        i.i_brand_id IN (6012006, 3002001)
        AND cc.cc_hours = '8AM-4PM'
        AND wsite.web_country = 'US'
    GROUP BY
        cc.cc_name,
        i.i_brand,
        i.i_category,
        sm.sm_type,
        wsite.web_name
    HAVING SUM(cs.cs_net_paid) > 10000
)
SELECT *
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_net_paid DESC) AS rn
    FROM base
) t
WHERE rn <= 10
ORDER BY total_net_paid DESC
LIMIT 100
