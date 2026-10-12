WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_customer_sk,
        cs.cs_catalog_page_sk
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_brand_id IN (6016006, 3003001)
      AND w.w_state = 'CA'
      AND td.t_hour BETWEEN 8 AND 12
),
returns_base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_reason_sk
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
),
sales_minus_returns AS (
    SELECT sb.*
    FROM sales_base sb
    EXCEPT
    SELECT sb2.*
    FROM sales_base sb2
    JOIN returns_base rb ON sb2.cs_order_number = rb.cr_order_number
),
anti_joined AS (
    SELECT sb.*
    FROM sales_minus_returns sb
    WHERE NOT EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_order_number = sb.cs_order_number
          AND cr2.cr_item_sk = sb.cs_item_sk
    )
),
ranked AS (
    SELECT
        aj.cs_order_number,
        aj.cs_item_sk,
        i.i_product_name,
        i.i_brand_id,
        w.w_warehouse_name,
        aj.cs_net_profit,
        RANK() OVER (PARTITION BY i.i_brand_id ORDER BY aj.cs_net_profit DESC) AS brand_profit_rank
    FROM anti_joined aj
    JOIN item i ON aj.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON aj.cs_warehouse_sk = w.w_warehouse_sk
)
SELECT
    final.cs_order_number,
    final.cs_item_sk,
    final.i_product_name,
    final.i_brand_id,
    final.w_warehouse_name,
    final.cs_net_profit,
    final.brand_profit_rank,
    final.profit_category
FROM (
    SELECT
        r.cs_order_number,
        r.cs_item_sk,
        r.i_product_name,
        r.i_brand_id,
        r.w_warehouse_name,
        r.cs_net_profit,
        r.brand_profit_rank,
        'HIGH' AS profit_category
    FROM ranked r
    WHERE r.brand_profit_rank <= 5

    UNION

    SELECT
        r.cs_order_number,
        r.cs_item_sk,
        r.i_product_name,
        r.i_brand_id,
        r.w_warehouse_name,
        r.cs_net_profit,
        r.brand_profit_rank,
        'LOW' AS profit_category
    FROM ranked r
    WHERE r.brand_profit_rank > 5 AND r.brand_profit_rank <= 10
) AS final
ORDER BY final.i_brand_id, final.brand_profit_rank
LIMIT 100
