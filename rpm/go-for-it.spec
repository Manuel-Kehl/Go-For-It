Name:		go-for-it

%if 0%{?with_git}
Version:	%{version}-%{commit}
%else
Version:	%{version}
%endif

%{!?release: %define release 1}

Release:	%{release}%{?dist}
Summary:	A simple to do app.

License:	GPLv3
URL:		https://github.com/mank319/Go-For-It
Source0:	go-for-it-%{version}.tar.gz

BuildRequires:	gtk3-devel
BuildRequires:	cmake
BuildRequires:	vala-devel
BuildRequires:	libnotify-devel
BuildRequires:	intltool

%description
A simple to do app.


%prep
%setup -q -n Go-For-It


%build
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=RelWithDebInfo .
%make_build


%install
%make_install


%files

%{_bindir}/com.github.jmoerman.go-for-it

%{_datarootdir}/applications/com.github.jmoerman.go-for-it.desktop

%{_datarootdir}/com.github.jmoerman.go-for-it/style/*.css

%{_datarootdir}/icons/hicolor/*/apps/com.github.jmoerman.go-for-it.svg
%{_datarootdir}/icons/hicolor/24x24/actions/com.github.jmoerman.go-for-it-open-menu-fallback.svg

%{_datarootdir}/locale/*/LC_MESSAGES/com.github.jmoerman.go-for-it.mo

%{_datarootdir}/metainfo/com.github.jmoerman.go-for-it.appdata.xml


%changelog

