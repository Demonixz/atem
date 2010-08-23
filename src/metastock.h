#ifndef METASTOCK_H
#define METASTOCK_H

#include <QtCore/QtContainerFwd>

class QFile;
class QByteArray;
struct master_record;


class Metastock
{
	public:
		Metastock();
		~Metastock();
		
		bool hasXMaster() const;
		
		bool setDir( const char* dir );
		void readMasters();
		
		void parseMasters();
		void dumpMaster() const;
		void dumpEMaster() const;
		void dumpXMaster() const;
		void dumpData( int f ) const;
		void dumpData( int number, unsigned int fields, const char *pfx) const;
		const char* lastError() const;
		
	private:
		void findFiles();
		QFile* findMaster( const char *name ) const;
		
		const char *dir;
		QFile *master;
		QFile *emaster;
		QFile *xmaster;
		QHash<QString, QString> *files;
		int mr_len;
		master_record **mr_list;
		
		QByteArray *ba_master;
		QByteArray *ba_emaster;
		QByteArray *ba_xmaster;
		
		mutable const char* error;
};



#endif
