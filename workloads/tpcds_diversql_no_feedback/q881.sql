WITH agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        t.t_hour,
        wp.wp_type,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_quantity) AS avg_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE t.t_time_sk = 10
      AND wp.wp_autogen_flag = 'N'
      AND c.c_birth_month = 9
      AND c.c_current_addr_sk = 4417012
    GROUP BY cd.cd_gender, cd.cd_marital_status, t.t_hour, wp.wp_type
)
SELECT
    cd_gender,
    cd_marital_status,
    t_hour,
    wp_type,
    total_net_paid,
    avg_quantity,
    distinct_tickets,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS row_num
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
