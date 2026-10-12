WITH sales_by_time AS (
    SELECT
        td.t_hour,
        td.t_time_id,
        cc.cc_manager,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(cs.cs_order_number) AS orders_cnt
    FROM catalog_sales cs
    RIGHT OUTER JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
           AND regexp_like(cc.cc_manager, 'Ray')
    WHERE td.t_time_id LIKE 'AAAA%'
    GROUP BY td.t_hour, td.t_time_id, cc.cc_manager
)
SELECT
    t_hour,
    CONCAT('Hour_', CAST(t_hour AS VARCHAR)) AS hour_label,
    t_time_id,
    COALESCE(cc_manager, 'No Manager') AS manager_name,
    SUBSTRING(COALESCE(cc_manager, 'No Manager') FROM 1 FOR 5) AS manager_prefix,
    total_net_profit,
    orders_cnt,
    regexp_extract(t_time_id, '(A{3,})', 1) AS extracted_pattern
FROM sales_by_time
ORDER BY t_hour ASC, total_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
