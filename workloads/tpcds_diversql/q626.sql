WITH
base AS (
    SELECT
        d.d_year,
        cc.cc_state,
        cd.cd_gender,
        ib.ib_lower_bound,
        t.t_hour,
        p.p_discount_active,
        cs.cs_order_number,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_promo_sk,
        ss.ss_ticket_number,
        ss.ss_customer_sk,
        ss.ss_ext_discount_amt,
        ss.ss_quantity,
        ss.ss_net_paid,
        sr.sr_reason_sk,
        cr.cr_return_amount,
        w.w_state,
        wp.wp_type,
        r.r_reason_desc,
        CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM date_dim d
    JOIN call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND cd.cd_gender = 'M'
      AND ib.ib_lower_bound >= 50000
      AND t.t_hour BETWEEN 9 AND 17
),
full_outer AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        t.t_hour,
        CASE WHEN ss.ss_quantity > 10 THEN 1 ELSE 0 END AS large_qty_flag
    FROM store_sales ss
    FULL OUTER JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
),
ticket_common AS (
    SELECT ss_ticket_number FROM store_sales
    INTERSECT
    SELECT sr_ticket_number FROM store_returns
),
union_part1 AS (
    SELECT
        profit_category,
        SUM(cs_net_paid_inc_tax) AS total_net_paid,
        COUNT(DISTINCT ss_customer_sk) AS uniq_customers,
        AVG(ss_ext_discount_amt) AS avg_discount
    FROM base
    WHERE EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_sk = base.cs_promo_sk
              AND p2.p_discount_active = 'Y'
          )
      AND ss_ticket_number IN (SELECT ss_ticket_number FROM ticket_common)
    GROUP BY profit_category
),
union_part2 AS (
    SELECT
        profit_category,
        SUM(cs_net_paid_inc_tax) AS total_net_paid,
        COUNT(DISTINCT ss_customer_sk) AS uniq_customers,
        AVG(ss_ext_discount_amt) AS avg_discount
    FROM base
    WHERE cs_quantity < 5
      AND wp_type = 'product'
      AND w_state = 'TX'
    GROUP BY profit_category
),
union_all AS (
    SELECT * FROM union_part1
    UNION
    SELECT * FROM union_part2
)
SELECT
    profit_category,
    SUM(total_net_paid) AS grand_total_net_paid,
    SUM(uniq_customers) AS total_customers,
    AVG(avg_discount) AS overall_avg_discount
FROM union_all
GROUP BY profit_category
ORDER BY grand_total_net_paid DESC
