WITH joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid_inc_tax,
        cc.cc_name,
        cc.cc_state,
        cp.cp_department,
        dd.d_year,
        wr.wr_net_loss
    FROM catalog_sales cs
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2001
      AND cc.cc_state = 'CA'
      AND cp.cp_department = 'Sports'
      AND wr.wr_reason_sk = 43
      AND cs.cs_net_paid_inc_tax > 1000
),
agg AS (
    SELECT
        cc_name,
        cp_department,
        d_year,
        SUM(cs_net_paid_inc_tax) AS total_net_paid,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM joined
    GROUP BY cc_name, cp_department, d_year
    HAVING SUM(cs_net_paid_inc_tax) > 5000
),
ranked AS (
    SELECT
        cc_name,
        cp_department,
        d_year,
        total_net_paid,
        total_net_loss,
        order_cnt,
        ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_net_paid DESC) AS rn
    FROM agg
)
SELECT
    cc_name,
    cp_department,
    d_year,
    total_net_paid,
    total_net_loss,
    order_cnt
FROM ranked
WHERE rn <= 5
LIMIT 100
