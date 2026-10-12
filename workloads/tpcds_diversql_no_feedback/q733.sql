WITH sales_per_hour AS (
   SELECT
       s.s_state,
       i.i_brand,
       p.p_channel_tv,
       t.t_hour,
       SUM(ss.ss_net_paid) AS total_paid,
       COUNT(*) AS sales_cnt
   FROM store_sales ss
   JOIN time_dim t
       ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i
       ON ss.ss_item_sk = i.i_item_sk
   JOIN store s
       ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p
       ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer c
       ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca
       ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd
       ON ss.ss_hdemo_sk = hd.hd_demo_sk
   RIGHT OUTER JOIN income_band ib
       ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN store_returns sr
       ON ss.ss_ticket_number = sr.sr_ticket_number
   LEFT JOIN reason r
       ON sr.sr_reason_sk = r.r_reason_sk
   LEFT JOIN web_sales ws
       ON i.i_item_sk = ws.ws_item_sk
   LEFT JOIN web_page wp
       ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN web_returns wr
       ON ws.ws_order_number = wr.wr_order_number
   WHERE ca.ca_state IN ('TX', 'MS')
     AND i.i_category = 'Sports'
     AND p.p_discount_active = 'Y'
     AND s.s_gmt_offset > -5
     AND t.t_hour BETWEEN 9 AND 17
     AND ib.ib_lower_bound >= 50000
     AND ss.ss_ticket_number NOT IN (
         SELECT sr2.sr_ticket_number
         FROM store_returns sr2
         WHERE sr2.sr_refunded_cash > 1000
     )
   GROUP BY s.s_state, i.i_brand, p.p_channel_tv, t.t_hour
)
SELECT
    s_state,
    i_brand,
    p_channel_tv,
    AVG(total_paid) AS avg_total_paid,
    SUM(sales_cnt) AS total_sales_cnt
FROM sales_per_hour
GROUP BY CUBE (s_state, i_brand, p_channel_tv)
LIMIT 100
