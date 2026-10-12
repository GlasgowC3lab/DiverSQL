WITH ss_part AS (
    SELECT d.d_year AS year,
           cd.cd_gender AS gender,
           concat(cd.cd_gender, '-', CAST(d.d_year AS varchar)) AS gender_year_key,
           sum(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    RIGHT OUTER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cd.cd_credit_rating LIKE 'A%'
      AND regexp_like(cd.cd_education_status, '^College')
      AND d.d_holiday = 'N'
    GROUP BY d.d_year,
             cd.cd_gender,
             concat(cd.cd_gender, '-', CAST(d.d_year AS varchar))
),
ws_part AS (
    SELECT d.d_year AS year,
           cd.cd_gender AS gender,
           concat(cd.cd_gender, '-', CAST(d.d_year AS varchar)) AS gender_year_key,
           sum(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    RIGHT OUTER JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE regexp_like(wsit.web_name, 'Online')
      AND wsit.web_state LIKE 'CA%'
      AND substring(wsit.web_city, 1, 3) = 'San'
    GROUP BY d.d_year,
             cd.cd_gender,
             concat(cd.cd_gender, '-', CAST(d.d_year AS varchar))
)
SELECT year,
       gender,
       gender_year_key,
       total_net_paid
FROM ss_part
UNION
SELECT year,
       gender,
       gender_year_key,
       total_net_paid
FROM ws_part
ORDER BY total_net_paid DESC
LIMIT 100
