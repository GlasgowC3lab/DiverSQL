WITH ss_sample AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        d.d_year,
        s.s_store_name,
        s.s_gmt_offset,
        we.web_site_sk,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) AS total_net_paid,
        CASE
            WHEN s.s_gmt_offset > (
                SELECT AVG(cc2.cc_gmt_offset)
                FROM call_center cc2
                WHERE cc2.cc_state = 'CA'
            ) THEN 'Above Avg Offset'
            ELSE 'Below Avg Offset'
        END AS offset_category
    FROM ss_sample ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
                     AND ss.ss_sold_time_sk = ws.ws_sold_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    JOIN call_center cc ON d.d_date_sk = cc.cc_closed_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'TX'
      AND we.web_country = 'United States'
      AND r.r_reason_desc LIKE '%price%'
      AND wp.wp_link_count > 10
    GROUP BY d.d_year, s.s_store_name, s.s_gmt_offset, we.web_site_sk
)
SELECT
    d_year,
    s_store_name,
    web_site_sk,
    store_net_paid,
    web_net_paid,
    total_net_paid,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS yearly_total_rank,
    offset_category
FROM joined
ORDER BY total_net_paid DESC
LIMIT 100
