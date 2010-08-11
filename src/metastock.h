#ifndef METASTOCK_H
#define METASTOCK_H

#include <QtCore/QtContainerFwd>

class QDir;
class QFile;
class QByteArray;
class QFileInfo;


class Metastock
{
	public:
		Metastock();
		~Metastock();
		
		bool hasXMaster() const;
		
		bool setDir( const char* dir );
		void readMasters();
		
		void dumpMaster() const;
		void dumpEMaster() const;
		void dumpXMaster() const;
		void dumpData( int f ) const;
		void dumpDataDAT( int f=0 ) const;
		void dumpDataMWD( int f=0 ) const;
		void dumpData( int number, int l ) const;
		const char* lastError() const;
		
	private:
		void findFiles();
		QFile* findMaster( const char *name ) const;
		
		QDir *dir;
		QFile *master;
		QFile *emaster;
		QFile *xmaster;
		QHash<QString, QFileInfo> *files;
		
		QByteArray *ba_master;
		QByteArray *ba_emaster;
		QByteArray *ba_xmaster;
		
		mutable const char* error;
};



#endif
