#module Time
import Base.Dates: UTInstant, Millisecond
import Base:+, -, string, show
using Base.Test


function datenum_cal(cm, y, m, d, h, mi, s, ms = 0)
    return 24*60*60*1000 * (cm[end] * (y-1) + cm[m] + (d-1)) + 60*60*1000 * h +  60*1000 * mi + 1000*s + ms
end

function datenum_julian(y, m, d, h, mi, s, ms = 0)
    # days elapsed since beginning of the year for every month
    cm = (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365)

    # number of leap years prior to current year
    nleap = (y-1) ÷ 4
    if y % 4 == 0
        # after Feb., count current leap day
        if m > 2
            nleap += 1
        end
    end

    return 24*60*60*1000 * (cm[end] * (y-1) + cm[m] + (d-1) + nleap) + 60*60*1000 * h +  60*1000 * mi + 1000*s + ms
end

"""
time is in milliseconds
"""
function datevec_julian(time::Number)
    days = time ÷ (24*60*60*1000)

    ym = (0, 365, 2*365, 3*365, 3*365+366)

    y4 = days ÷ (3*365+366)
    #@show y4

    y = 4*y4 + findlast(ym .<=  (days % (3*365+366)))-1

    #y = (days*4) ÷ (3*365+366)
    #@show y, days
    days = days - (365*y + (y)÷4)

    #@show days

    cm =
        if (y+1) % 4 == 0
            # leap year
            (0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366)
        else
            (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365)
        end

    mo = findlast(cm .<= days)
    d = days  - cm[mo]

    ms = time % (24*60*60*1000)
    h = ms ÷ (60*60*1000)
    ms = ms % (60*60*1000)

    mi = ms ÷ (60*1000)
    ms = ms % (60*1000)

    s = ms ÷ (1000)
    ms = ms % (1000)

    # day start at 1 (not zero)
    d = d+1
    y = y+1

    #@show y,mo,d,h,mi,s,ms
    return (y,mo,d,h,mi,s,ms)
end


function datevec_cal(cm,time_::Number)
    timed_ = time_ ÷ (24*60*60*1000)

    y = timed_ ÷ cm[end]

    t2 = timed_ - cm[end]*y

    mo = findlast(cm .<= t2)

    d = t2  - cm[mo]

    ms = time_ % (24*60*60*1000)
    h = ms ÷ (60*60*1000)
    ms = ms % (60*60*1000)

    mi = ms ÷ (60*1000)
    ms = ms % (60*1000)

    s = ms ÷ (1000)
    ms = ms % (1000)

    # day and year start at 1 (not zero)
    d = d+1;
    y = y+1;

    return (y,mo,d,h,mi,s,ms)
end

datevec_cal(cm,dt) = datevec_cal(cm,Dates.value(dt.instant.periods))

abstract type AbstractCFDateTime end

const RegTime = Union{Dates.Millisecond,Dates.Second,Dates.Minute,Dates.Hour,Dates.Day}





for (CFDateTime,cmm) in [
    (:DateTimeAllLeap, (0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366)),
    (:DateTimeNoLeap,  (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365)),
    (:DateTime360,     (0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 360)),
]
    @eval begin
        # adapted from
        # https://github.com/JuliaLang/julia/blob/aa301aa60bb7097182c55248572c861361a40b53/stdlib/Dates/src/types.jl
        # Licence MIT

        struct $CFDateTime <: AbstractCFDateTime
            instant::UTInstant{Millisecond}
            $CFDateTime(instant::UTInstant{Millisecond}) = new(instant)
        end


"""
     CFDateTime(y, [m, d, h, mi, s, ms])
Construct a `DateTime` type by parts. Arguments must be convertible to [`Int64`](@ref).
"""
function $CFDateTime(y::Int64, m::Int64=1, d::Int64=1,
                  h::Int64=0, mi::Int64=0, s::Int64=0, ms::Int64=0)

    if m < 1 || m > 12
        error("invalid month $(m)")
    end

    return $CFDateTime(UTInstant(Millisecond(datenum_cal($cmm,y, m, d, h, mi, s, ms))))
end

datevec(dt::$CFDateTime) = datevec_cal($cmm,dt)


function string(dt::$CFDateTime)
    y,mo,d,h,mi,s,ms = datevec(dt)
    return @sprintf("%04d-%02d-%02dT%02d:%02d:%02d",y,mo,d,h,mi,s)
end

function show(io::IO,dt::$CFDateTime)
    write(io, string(typeof(dt)), "(",string(dt),")")
end


+(dt::$CFDateTime,Δ::RegTime) = $CFDateTime(UTInstant(dt.instant.periods + Dates.Millisecond(Δ)))
+(dt::$CFDateTime,Δ::Dates.Year) = $CFDateTime(UTInstant(dt.instant.periods + Dates.Millisecond(Dates.value(Δ) * $cmm[end]*24*60*60*1000)))

function +(dt::$CFDateTime,Δ::Dates.Month)
    y,mo,d,h,mi,s,ms = datevec(dt)
    mo = mo + Dates.value(Δ)
    mo2 = mod(mo - 1, 12) + 1

    y = y + (mo-mo2) ÷ 12
    return $CFDateTime(y, mo2, d,h, mi, s, ms)
end

end
    end

# struct DateTimeNoLeap
#     instant::UTInstant{Millisecond}
#     DateTimeNoLeap(instant::UTInstant{Millisecond}) = new(instant)
# end


# cm_noleap = (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365)
  # if strcmp(calendar,'noleap') || strcmp(calendar,'365_day') || strcmp(calendar,'bogus_calendar')
  #   %cm = [0 cumsum([31 28 31 30 31 30 31 31 30 31 30 31])];
  #   cm = [0    31    59    90   120   151   181   212   243   273   304   334   365];
  # elseif strcmp(calendar,'360_day')
  #   cm = [0 30 60 90 120 150 180 210 240 270 300 330 360];
  # else
  #   %[0 cumsum([31 29 31 30 31 30 31 31 30 31 30 31])]
  #   cm = [0    31    60    91   121   152   182   213   244   274   305   335   366];
  # end





year(dt::AbstractCFDateTime) = datevec(dt)[1]
month(dt::AbstractCFDateTime) = datevec(dt)[2]
day(dt::AbstractCFDateTime) = datevec(dt)[3]
hour(t::AbstractCFDateTime)   = datevec(dt)[4]
minute(dt::AbstractCFDateTime) = datevec(dt)[5]
second(dt::AbstractCFDateTime) = datevec(dt)[6]
millisecond(dt::AbstractCFDateTime) = datevec(dt)[7]


-(dt::AbstractCFDateTime,Δ) = dt + (-Δ)

# dvec = [1959,12,31, 23,39,59,123];
# t =  datenum_cal(cm_noleap,dvec...)
# dvec2 = datevec_cal(cm_noleap,t)
# @show dvec
# @show dvec2
# @test maximum(abs.(dvec-[dvec2...])) ≈ 0 atol=1e-3

dt = DateTimeNoLeap(1959,12,31, 23,39,59,123)
@test year(dt) == 1959
@test month(dt) == 12
@test day(dt) == 31
@test hour(dt) == 23
@test minute(dt) == 39
@test second(dt) == 59
@test millisecond(dt) == 123

@test datevec(DateTimeNoLeap(1959,12,31, 23,39,59,123)) == (1959,12,31, 23,39,59,123)


dt = DateTimeNoLeap(1959,12,31,23,39,59,123)
@test dt + Dates.Millisecond(7) == DateTimeNoLeap(1959,12,31,23,39,59,130)
@test dt + Dates.Second(7)      == DateTimeNoLeap(1959,12,31,23,40,6,123)
@test dt + Dates.Minute(7)      == DateTimeNoLeap(1959,12,31,23,46,59,123)
@test dt + Dates.Hour(7)        == DateTimeNoLeap(1960,1,1,6,39,59,123)
@test dt + Dates.Day(7)         == DateTimeNoLeap(1960,1,7,23,39,59,123)
@test dt + Dates.Month(7)       == DateTimeNoLeap(1960,7,31,23,39,59,123)
@test dt + Dates.Year(7)        == DateTimeNoLeap(1966,12,31,23,39,59,123)
@test dt + Dates.Month(24)      == DateTimeNoLeap(1961,12,31,23,39,59,123)

@test dt - Dates.Month(0)       == DateTimeNoLeap(1959,12,31,23,39,59,123)
@test dt - Dates.Month(24)      == DateTimeNoLeap(1957,12,31,23,39,59,123)
@test dt - Dates.Year(7)        == DateTimeNoLeap(1952,12,31,23,39,59,123)


dt = DateTimeNoLeap(2004,2,28)
@test dt + Dates.Day(1)         == DateTimeNoLeap(2004,3,1)

@test string(DateTimeNoLeap(2001,2,20)) == "2001-02-20T00:00:00"


dt = DateTimeAllLeap(2001,2,28)
@test dt + Dates.Day(1)         == DateTimeAllLeap(2001,2,29)
@test datevec(DateTimeAllLeap(1959,12,31, 23,39,59,123)) == (1959,12,31, 23,39,59,123)


@test datevec(DateTime360(1959,12,30,23,39,59,123)) == (1959,12,30,23,39,59,123)


for n = 1:800000
    @test datenum_julian(datevec_julian(n*24*60*60*1000)...) ÷ (24*60*60*1000) == n
end