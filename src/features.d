﻿module src.features;

interface AppInterface
{
	void run();
	void command(in string[] args);
	
}

interface UserInterfaceFeatures
{
	void run();
	shared void command(in string[] args);
}

shared interface CommInterface
{
	void command(in string[] args);
}
