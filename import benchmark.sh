apt-get update && apt-get -y dist-upgrade && shutdown -r now
# wait for reboot

# as root
apt-get autoremove -y --purge

# basics and osm2pgsql deps
apt-get install -y subversion git build-essential libxml2-dev libgeos-dev libgeos++-dev libpq-dev libbz2-dev libproj-dev protobuf-c-compiler libprotobuf-c0-dev autoconf automake libtool make g++ sysstat iotop apache2.2 apache2.2-common apache2-mpm-worker liblua5.2-dev lua5.2

mkdir -m 000 /planet
# for downloading new planet, do the below
#mkfs.ext4 /dev/xvdc
echo "/dev/xvdc /planet ext4 noatime 0 0" >> /etc/fstab
mount /planet
chown ubuntu:ubuntu /planet/

umount /mnt
mkfs.ext4 /dev/xvdb
mount /mnt

#not as root
#cd /planet/
#curl --remote-name-all "http://planet.openstreetmap.org/pbf/planet-130509.osm.pbf{.md5,}"

#back to root
PGCONF="/etc/postgresql/9.1/main/postgresql.conf"

apt-get --no-install-recommends install -y postgresql-9.1
/etc/init.d/postgresql stop
mkdir /mnt/postgresql
sed -i "s/data_directory = '\/var\/lib\/postgresql\/9.1\/main'/data_directory = '\/mnt\/postgresql\/9.1\/main'/" $PGCONF
mv /var/lib/postgresql/9.1 /mnt/postgresql/
chown -R postgres:postgres /mnt/postgresql
/etc/init.d/postgresql start

add-apt-repository ppa:kakrueger/openstreetmap
apt-get update
apt-get --no-install-recommends -y install renderd postgresql-9.1-postgis openstreetmap-postgis-db-setup

sysctl -w kernel.shmmax=8589934592
sysctl -w kernel.shmall=2097152

sed -i "s/#shared_buffers = 32MB/shared_buffers = 1GB/" $PGCONF
sed -i "s/#effective_cache_size = 128MB/effective_cache_size = 20GB/" $PGCONF

#checkpoint settings
sed -i "s/#checkpoint_segments = 3/checkpoint_segments = 256/" $PGCONF
sed -i "s/#checkpoint_completion_target = 0.5/checkpoint_completion_target = 0.9/" $PGCONF

sed -i "s/#wal_buffers = -1/wal_buffers = 16MB/" $PGCONF

# fsync methods
sed -i "s/#wal_sync_method = fsync/wal_sync_method = open_sync/" $PGCONF

sed -i "s/#synchronous_commit = on/synchronous_commit = off/" $PGCONF

sed -i "s/#fsync = on/fsync = off/" $PGCONF

sed -i "s/#random_page_cost = 4.0/random_page_cost = 2.0/" $PGCONF
sed -i "s/autovacuum = on/autovacuum = off/" $PGCONF
sed -i "s/#maintenance_work_mem = 16MB/maintenance_work_mem = 1GB/" $PGCONF

/etc/init.d/postgresql restart

mkdir /mnt/flat
chown ubuntu:ubuntu /mnt/flat

#exit root
git clone https://github.com/openstreetmap/osm2pgsql
cd osm2pgsql/
./autogen.sh
./configure
make
sudo make install

