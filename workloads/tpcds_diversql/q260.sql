WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        i.i_category,
        p.p_promo_name,
        SUM(ss.ss_net_paid)                         AS total_sales,
        SUM(ss.ss_net_profit)                       AS total_profit,
        COALESCE(SUM(sr.sr_net_loss), 0)            AS total_store_return_loss,
        COALESCE(SUM(wr.wr_net_loss), 0)            AS total_web_return_loss,
        AVG(p.p_cost)                               AS avg_promo_cost,
        COUNT(DISTINCT CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_order_number END) AS web_return_orders
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        t.t_minute IN (4, 19, 1)
        AND t.t_shift = 'second'
        AND c.c_salutation = 'Mr.'
        AND s.s_state = 'CA'
        AND p.p_discount_active = 'Y'
        AND i.i_brand = 'BrandXYZ'
        AND wp.wp_char_count > 1000
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        i.i_category,
        p.p_promo_name
),
high_sales AS (
    SELECT s_store_id, total_sales
    FROM base
    WHERE total_sales > 150000
),
promo_active AS (
    SELECT s_store_id
    FROM base
    WHERE avg_promo_cost < 20
),
expensive_promo AS (
    SELECT s_store_id
    FROM base
    WHERE avg_promo_cost > 50
),
good_stores AS (
    SELECT s_store_id
    FROM high_sales
    INTERSECT
    SELECT s_store_id
    FROM promo_active
),
final_set AS (
    SELECT
        b.s_store_id,
        b.s_store_name,
        b.total_sales,
        b.total_profit,
        (b.total_sales - b.total_store_return_loss - b.total_web_return_loss) AS net_revenue
    FROM base b
    WHERE b.s_store_id IN (
        SELECT s_store_id FROM good_stores
        EXCEPT
        SELECT s_store_id FROM expensive_promo
    )
)
SELECT
    s_store_id,
    s_store_name,
    total_sales,
    total_profit,
    net_revenue
FROM final_set
ORDER BY net_revenue DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
