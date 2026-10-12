WITH cs_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_bill_addr_sk,
        ca.ca_city AS city,
        ca.ca_state AS state,
        p.p_promo_name,
        p.p_discount_active
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_quantity > 5
      AND cs.cs_ext_sales_price > 1000
      AND p.p_discount_active = 'Y'
      AND ca.ca_state = 'CA'
      AND cs.cs_sold_date_sk BETWEEN 2452000 AND 2452100
),
wr_data AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_refunded_addr_sk,
        ca.ca_city AS refund_city,
        ca.ca_state AS refund_state,
        r.r_reason_desc,
        wp.wp_image_count,
        wp.wp_type
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 50
      AND r.r_reason_desc LIKE '%defect%'
      AND wp.wp_type = 'product'
      AND ca.ca_state = 'CA'
),
joined_data AS (
    SELECT
        COALESCE(cs.city, wr.refund_city) AS city,
        COALESCE(cs.state, wr.refund_state) AS state,
        cs.p_promo_name,
        wr.r_reason_desc,
        wr.wp_type,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_order_number,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_order_number
    FROM cs_data cs
    FULL OUTER JOIN wr_data wr
        ON cs.cs_bill_addr_sk = wr.wr_refunded_addr_sk
    WHERE cs.cs_ext_sales_price > (
            SELECT MAX(cs_ext_sales_price)
            FROM catalog_sales
            WHERE cs_quantity > 10
          )
),
aggregated AS (
    SELECT
        city,
        state,
        p_promo_name,
        r_reason_desc,
        wp_type,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_quantity) AS total_quantity,
        AVG(cs_net_profit) AS avg_profit,
        SUM(wr_return_amt) AS total_return_amount,
        MAX(wr_net_loss) AS max_net_loss,
        COUNT(DISTINCT cs_order_number) AS distinct_sales_orders,
        COUNT(DISTINCT wr_order_number) AS distinct_return_orders
    FROM joined_data
    GROUP BY city, state, p_promo_name, r_reason_desc, wp_type
)
SELECT
    city,
    state,
    p_promo_name,
    r_reason_desc,
    wp_type,
    total_sales,
    total_quantity,
    avg_profit,
    total_return_amount,
    max_net_loss,
    distinct_sales_orders,
    distinct_return_orders,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_sales DESC) AS state_sales_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
