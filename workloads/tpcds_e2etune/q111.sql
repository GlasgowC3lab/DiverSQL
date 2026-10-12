WITH returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_call_center_id,
        cc.cc_name,
        ws.web_site_id,
        cp.cp_catalog_page_id,
        cd.cd_gender,
        cd.cd_education_status,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_quantity,
        (SUM(wr.wr_net_loss) / NULLIF(SUM(wr.wr_return_quantity), 0)) AS net_loss_per_item
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cc.cc_state = 'TN'
        AND cc.cc_class = 'large'
        AND cd.cd_gender = 'F'
        AND cd.cd_education_status = 'College'
        AND d.d_year = 2002
    GROUP BY
        d.d_year,
        d.d_month_seq,
        cc.cc_call_center_id,
        cc.cc_name,
        ws.web_site_id,
        cp.cp_catalog_page_id,
        cd.cd_gender,
        cd.cd_education_status
    HAVING COUNT(*) > 5
)
SELECT
    r.*, 
    RANK() OVER (ORDER BY r.total_net_loss DESC) AS net_loss_rank
FROM returns_agg r
ORDER BY r.total_net_loss DESC
LIMIT 10
