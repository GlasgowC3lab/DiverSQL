WITH cat_sales AS (
        SELECT
            i.i_category,
            i.i_brand,
            SUM(cs.cs_net_profit) AS profit,
            'catalog' AS channel
        FROM catalog_sales cs
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        WHERE td.t_hour BETWEEN 9 AND 17
          AND p.p_cost > 500
          AND i.i_color = 'ivory'
        GROUP BY GROUPING SETS (
            (i.i_category, i.i_brand),
            (i.i_category),
            ()
        )
    ),
    web_sales_cte AS (
        SELECT
            i.i_category,
            i.i_brand,
            SUM(ws.ws_net_profit) AS profit,
            'web' AS channel,
            SUM(wr.wr_net_loss) AS return_loss
        FROM web_sales ws
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = i.i_item_sk
            AND wr.wr_returned_time_sk = td.t_time_sk
        LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE td.t_hour BETWEEN 9 AND 17
          AND p.p_cost > 500
          AND i.i_color = 'ivory'
          AND (r.r_reason_desc IS NULL OR r.r_reason_desc <> 'Customer Not Satisfied')
        GROUP BY GROUPING SETS (
            (i.i_category, i.i_brand),
            (i.i_category),
            ()
        )
    ),
    union_sales AS (
        SELECT i_category, i_brand, profit, channel FROM cat_sales
        UNION DISTINCT
        SELECT i_category, i_brand, profit, channel FROM web_sales_cte
    )
SELECT
    i_category,
    i_brand,
    SUM(profit) AS total_profit,
    COUNT(DISTINCT channel) AS channels_present,
    RANK() OVER (PARTITION BY i_category ORDER BY SUM(profit) DESC) AS rank_within_category
FROM union_sales
GROUP BY GROUPING SETS (
    (i_category, i_brand),
    (i_category),
    ()
)
ORDER BY total_profit DESC
LIMIT 100
