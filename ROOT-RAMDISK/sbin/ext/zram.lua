#!/sbin/lua
-- /proc/swaps lists as used mem_used_total + zero_pages

for line in io.lines('/proc/meminfo') do
    SwapCached = line:match('SwapCached.* (%d+)') or SwapCached
end

zram_devices = {}
for line in io.lines('/proc/swaps') do
    table.insert(zram_devices, line:match('^/dev/block/(zram%d+)'))
end

--Let's store memory values in KiB in following dict
--Total stats dict
ts = {}
function read_zram_stat(stat)
    for i,zram_dev in pairs(zram_devices) do
        fh = io.open('/sys/block/' .. zram_dev .. '/' .. stat)
        ts[stat] = (ts[stat] or 0) + fh:read('*n')
        fh:close()
    end
end

function print_stat(label, value, suffix)
    local fmt='%-27s ' .. ( ({math.modf(value)})[2]>0 and '%.2f' or '%s' ) .. '%s'
    print(fmt:format(label .. ':', value, suffix or ''))
end

for i,stat in pairs({'compr_data_size', 'mem_used_total', 'orig_data_size', 'zero_pages', 'disksize'}) do
    read_zram_stat(stat)
    if stat == 'zero_pages' then
        ts[stat] = ts[stat]*4
    else
        ts[stat] = ts[stat]/1024
    end
    print_stat(stat, ts[stat], ' KiB')
end
print()

for i,stat in pairs({'notify_free', 'num_reads', 'num_writes'}) do
    read_zram_stat(stat)
    print_stat(stat, ts[stat])
end
print()

print_stat('SwapCached', SwapCached, ' KiB')
saved = ts['orig_data_size'] + ts['zero_pages'] - ts['mem_used_total'] - SwapCached
print_stat('Memory saved', saved, ' KiB')
print_stat('Compression', ts['compr_data_size']*100/ts['orig_data_size'], '%')
print_stat('Compression with overhead', ts['mem_used_total']*100/ts['orig_data_size'], '%')
print_stat('Used', 100*(ts['orig_data_size']+ts['zero_pages'])/ts['disksize'], '%')
