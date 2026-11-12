{% set nights_booked= 1212%}
{% set flag= 1 %}

select * from {{ref('bronze_bookings')}}
{% if flag == 2%}
    where NIGHTS_BOOKED = {{nights_booked}}
{% else %}
    where NIGHTS_BOOKED = 1
{% endif%}